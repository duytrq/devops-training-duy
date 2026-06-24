# Stage 1: Builder
FROM node:20 AS builder

# Thiết lập thư mục làm việc
WORKDIR /usr/src/app

# Sao chép mã nguồn của ứng dụng
COPY app/ ./app/

# Stage 2: Runtime
FROM node:20-alpine AS runtime

# Thiết lập các nhãn OCI (Open Container Initiative)
LABEL org.opencontainers.image.title="Simple Node.js Server" \
      org.opencontainers.image.description="A simple lightweight HTTP server running on Node.js alpine" \
      org.opencontainers.image.source="https://github.com/duytrq/devops-training-duy" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT"

# Thiết lập biến môi trường mặc định
ENV NODE_ENV=production \
    PORT=3000

# Tạo thư mục làm việc và gán quyền cho user node
WORKDIR /usr/src/app

# Sao chép ứng dụng từ stage builder và gán quyền cho user node
COPY --from=builder --chown=node:node /usr/src/app/app ./app

# Sử dụng non-root user mặc định của image Node (node)
USER node

# Khai báo port ứng dụng lắng nghe
EXPOSE 3000

# Cấu hình Healthcheck sử dụng wget tích hợp sẵn trong busybox (alpine)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

# Lệnh khởi chạy ứng dụng
CMD ["node", "app/server.js"]
