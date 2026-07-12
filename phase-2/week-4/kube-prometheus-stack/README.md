# Task: Week 4 — kube-prometheus-stack

- **Intern**: Trương Quang Duy
- **Phase/Week/Day**: phase-2/week-4/
- **Branch**: phase-2/week-4/
- **Submitted at**: 2026-07-12
- **Time spent**: 6h

## Mục tiêu

Cài `kube-prometheus-stack` bằng Helm, expose Grafana qua Ingress, import dashboard Grafana ID `1860` (`Node Exporter Full`), và tạo alert `PrometheusRule` khi pod restart hơn 3 lần trong 10 phút.

## Thực hiện

### 1. Chuẩn bị Ingress controller cho k3d

Dùng Traefik mặc định của k3d/k3s

Trong `values.yaml`, Grafana Ingress sẽ dùng:

```yaml
grafana:
  ingress:
    enabled: true
    ingressClassName: traefik
```

Đây là cách đơn giản nhất trên k3d nếu Traefik đã có sẵn.

### 2. Thêm Helm repository

Thêm repo của Prometheus Community:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Kiểm tra chart:

```bash
helm search repo prometheus-community/kube-prometheus-stack
```

### 3. Tạo namespace monitoring

```bash
kubectl create namespace monitoring
```

Nếu namespace đã tồn tại, có thể bỏ qua lỗi `AlreadyExists`.

### 4. Tạo file values.yaml

Nếu dùng Traefik mặc định của k3d, tạo `values.yaml` như sau:

```yaml
grafana:
  enabled: true

  adminPassword: admin123

  ingress:
    enabled: true
    ingressClassName: traefik
    hosts:
      - localhost
    paths:
      - /

  dashboards:
    default:
      node-exporter-full:
        gnetId: 1860
        revision: 37
        datasource: Prometheus
```

Giải thích:

- `gnetId: 1860` là dashboard `Node Exporter Full`.
- `datasource: Prometheus` trỏ dashboard về datasource Prometheus được chart tạo sẵn.
- `adminPassword: admin123` chỉ phù hợp cho lab.

### 5. Cài kube-prometheus-stack bằng Helm

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml
```

Kiểm tra pod:

```bash
kubectl get pods -n monitoring
```

Các component chính cần chạy:

- Prometheus Operator
- Prometheus
- Alertmanager
- Grafana
- node-exporter
- kube-state-metrics

### 6. Kiểm tra Service và Ingress của Grafana

```bash
kubectl get svc -n monitoring
kubectl get ingress -n monitoring
```

### 7. Truy cập Grafana trên k3d

Vì cluster hiện tại chưa map port `80/443`, dùng port-forward tới Ingress controller.

Nếu dùng Traefik:

```bash
kubectl -n kube-system port-forward svc/traefik 8080:80
```

Mở Grafana:

```text
http://localhost:8080
```

Thông tin đăng nhập theo `values.yaml`:

```text
username: admin
password: admin123
```

Nếu không set `adminPassword`, lấy password từ secret:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

### 8. Kiểm tra dashboard ID 1860

Trong Grafana:

1. Vào `Dashboards`.
2. Tìm dashboard `Node Exporter Full`.
3. Kiểm tra các panel CPU, memory, disk, filesystem, network.
4. Đảm bảo datasource là `Prometheus`.

### 9. Tạo PrometheusRule alert Pod restart

Tạo file `pod-restart-rule.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: pod-restart-alerts
  namespace: monitoring
  labels:
    release: kube-prometheus-stack
spec:
  groups:
    - name: pod-restart.rules
      rules:
        - alert: PodRestartMoreThan3TimesIn10Minutes
          expr: increase(kube_pod_container_status_restarts_total[10m]) > 3
          for: 0m
          labels:
            severity: warning
          annotations:
            summary: 'Pod restarted more than 3 times in 10 minutes'
            description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container }} restarted more than 3 times in the last 10 minutes.'
```

Apply rule:

```bash
kubectl apply -f pod-restart-rule.yaml
```

Giải thích:

- `release: kube-prometheus-stack` giúp Prometheus instance của Helm chart discover rule này.
- Metric `kube_pod_container_status_restarts_total` đến từ `kube-state-metrics`.
- `increase(...[10m]) > 3` nghĩa là restart counter tăng hơn 3 lần trong 10 phút.

### 10. Kiểm tra PrometheusRule

```bash
kubectl get prometheusrule -n monitoring
kubectl describe prometheusrule pod-restart-alerts -n monitoring
```

Port-forward Prometheus:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Mở:

```text
http://localhost:9090
```

Kiểm tra:

- `Status` -> `Rules`
- `Alerts`
- Query PromQL:

```promql
increase(kube_pod_container_status_restarts_total[10m]) > 3
```

### 11. Test alert

Tạo file `crashloop-test.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crashloop-test
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crashloop-test
  template:
    metadata:
      labels:
        app: crashloop-test
    spec:
      containers:
        - name: crashloop-test
          image: busybox:1.36
          command:
            - sh
            - -c
            - exit 1
```

Apply:

```bash
kubectl apply -f crashloop-test.yaml
```

Theo dõi restart:

```bash
kubectl get pods -n default -w
```

Sau khi container restart hơn 3 lần trong vòng 10 phút, kiểm tra lại Prometheus alert.
