# Task: K8s Deep dive P2

- **Intern**: Trương Quang Duy
- **Phase/Week/Day**: phase-2/week-3/k8s
- **Branch**: phase-2/week-3/k8s
- **Submitted at**: 2026-07-06
- **Time spent**: 6h

# Mục tiêu

P1: Triển khai demo-app trên k3d bằng deployment rollout, tạo services Cluster IP, Ingress và tạo TLS cert cho demoapp

P2: Sử dụng HPA để autoscale deployment, đóng gói ứng dụng bằng Helm và deploy bằng Helm Chart

Image được lấy từ repo: https://github.com/duytrq/cicd_basics/pkgs/container/demo-app

## 1. Tạo cluster k3d

Tạo một server, hai agent và publish cả HTTP lẫn HTTPS từ load balancer của
k3d ra máy host:

```bash
k3d cluster create dev \
  --servers 1 \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait
```

## 2. Cấu hình hostname cục bộ

Các ví dụ bên dưới sử dụng hostname `demo.local`. Thêm vào `/etc/hosts` trên
máy gửi request:

```text
127.0.0.1 demo.local
```

Nếu gọi từ trình duyệt Windows trong khi k3d chạy trong WSL2, có thể phải thêm
dòng tương tự vào file hosts của Windows bằng quyền Administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Không muốn sửa hosts thì dùng `curl --resolve` trong các bước kiểm tra.

## 3. Deployment, Service và Ingress HTTP

File [`demoapp.yml`](./demoapp.yml) hiện chứa:

- `Deployment` chạy ba replica từ image GHCR.
- `ClusterIP Service` nhận cổng `80` và forward tới cổng `3000` của container.
- `Ingress` forward path `/` tới Service.

Nên khai báo rõ `ingressClassName` và hostname. Cấu hình hoàn chỉnh cho HTTP:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app-deployment
  labels:
    app: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: demo-app
          image: ghcr.io/duytrq/demo-app:sha-918f30ed346f9e6f9bbd0d8ca876934699413d12
          ports:
            - name: http
              containerPort: 3000
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 2
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 250m
              memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
spec:
  type: ClusterIP
  selector:
    app: demo-app
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: http
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
spec:
  ingressClassName: traefik
  rules:
    - host: demo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo-app
                port:
                  number: 80
```

Đồng bộ nội dung cần thiết vào `demoapp.yml`, sau đó deploy theo cách khai báo:

```bash
kubectl apply -f demoapp.yml
kubectl rollout status deployment/demo-app-deployment --timeout=120s
```

Kiểm tra HTTP:

```bash
curl --resolve demo.local:8080:127.0.0.1 \
  http://demo.local:8080/health

curl --resolve demo.local:8080:127.0.0.1 \
  http://demo.local:8080/goat
```

## 4. Cập nhật Deployment

```bash
NEW_IMAGE=ghcr.io/duytrq/demo-app:<new-tag-or-digest>

kubectl set image deployment/demo-app-deployment \
  demo-app="$NEW_IMAGE"

kubectl rollout status deployment/demo-app-deployment --timeout=120s
```

Theo dõi, rollback và scale

```bash
kubectl rollout history deployment/demo-app-deployment
kubectl get pods -l app=demo-app -w
```

## 5. TLS termination

### 5.1 Tạo certificate có SAN

```bash
mkdir -p .certs

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout .certs/demo.local.key \
  -out .certs/demo.local.crt \
  -days 365 \
  -subj "/CN=demo.local/O=Local Development" \
  -addext "subjectAltName=DNS:demo.local"
```

Không commit private key `.certs/demo.local.key` vào Git.

Kiểm tra certificate:

```bash
openssl x509 -in .certs/demo.local.crt -noout \
  -subject -issuer -dates -ext subjectAltName
```

### 5.2 Tạo Kubernetes TLS Secret

Secret phải nằm cùng namespace với Ingress:

```bash
kubectl create secret tls demo-app-tls \
  --cert=.certs/demo.local.crt \
  --key=.certs/demo.local.key \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 5.3 Bật TLS trên Ingress

Thêm `spec.tls` vào Ingress trong `demoapp.yml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - demo.local
      secretName: demo-app-tls
  rules:
    - host: demo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo-app
                port:
                  number: 80
```

Áp dụng và kiểm tra:

```bash
kubectl apply -f demoapp.yml
kubectl get secret demo-app-tls
kubectl describe ingress demo-app-ingress

curl --cacert .certs/demo.local.crt \
  --resolve demo.local:8443:127.0.0.1 \
  https://demo.local:8443/health
```

## 6. Horizontal Pod Autoscaler (HPA)

Để tự động điều chỉnh số lượng replica của `demo-app-deployment` dựa trên mức sử dụng CPU thực tế, ta sử dụng Horizontal Pod Autoscaler (HPA).

### 6.1 File cấu hình HPA (`hpa.yml`)

Nội dung file [hpa.yml](./hpa.yml):

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-app-deployment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app-deployment
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### 6.2 Áp dụng và kiểm tra HPA

Triển khai HPA:

```bash
kubectl apply -f hpa.yml
```

Kiểm tra trạng thái HPA:

```bash
kubectl get hpa
```

Xem chi tiết hoạt động của HPA:

```bash
kubectl describe hpa demo-app-deployment
```

Để giả lập tải (load testing) và kiểm tra khả năng tự động scale:

```bash
# Chạy một pod tạm để bắn request liên tục tạo tải
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://demo-app/health > /dev/null; done"
```

Theo dõi sự thay đổi của replicas:

```bash
kubectl get hpa -w
```

## 7. Quản lý và đóng gói ứng dụng bằng Helm Chart

Để dễ dàng quản lý phiên bản, cấu hình động và tái sử dụng, toàn bộ tài nguyên trên đã được đóng gói thành một Helm Chart đặt trong thư mục [`demo-app/`](./demo-app).

### 7.1 Cấu trúc thư mục Helm Chart

```text
demo-app/
├── Chart.yaml          # Thông tin metadata của Chart (tên, phiên bản, appVersion)
├── values.yaml         # Các cấu hình mặc định (replicaCount, image, resources, ingress, autoscaling...)
├── templates/          # Thư mục chứa các template Kubernetes YAML
│   ├── _helpers.tpl    # Định nghĩa các helper template dùng chung
│   ├── deployment.yaml # Template cho Deployment
│   ├── hpa.yaml        # Template cho HPA (chỉ kích hoạt nếu autoscaling.enabled=true)
│   ├── service.yaml    # Template cho Service
│   └── ingress.yaml    # Template cho Ingress (hỗ trợ bật/tắt TLS)
```

### 7.2 Cài đặt và cập nhật ứng dụng bằng Helm

Cài đặt hoặc cập nhật (upgrade) release `demo-app` từ thư mục Chart:

```bash
helm upgrade --install demo-app ./demo-app
```

Kiểm tra danh sách các ứng dụng đang chạy qua Helm:

```bash
helm list
```

Xem danh sách tài nguyên và trạng thái thực tế của release:

```bash
helm status demo-app
```

### 7.3 Gỡ bỏ ứng dụng

Khi không cần thiết, có thể gỡ bỏ toàn bộ tài nguyên được tạo bởi Helm bằng lệnh:

```bash
helm uninstall demo-app
```
