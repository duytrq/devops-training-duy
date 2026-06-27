# Task: Day 10 — Observability Basics

- **Intern**: Trương Quang Duy
- **Phase/Week/Day**: phase-1/week-2/day-5-observability
- **Branch**: phase-1/week-2/day-5-observability
- **Submitted at**: 2026-06-27
- **Time spent**: 5h

## Mục tiêu

- Hiểu 3 trụ cột: **logs, metrics, traces**.
- Dựng được stack mini: Prometheus + Grafana + node-exporter.
- Biết khái niệm SLO / SLI / Error Budget.

## Cách chạy và kết quả chi tiết

### Part A — Notes

1. Phân biệt log vs metric vs trace (ví dụ cụ thể).
2. Pull-based (Prometheus) vs Push-based (StatsD, OpenTelemetry collector) — ưu nhược.
3. SLI / SLO / SLA khác nhau thế nào? Cho 1 ví dụ.
4. Cardinality nổ là gì, hậu quả?

Trả lời ở trong [này](./notes.md)

### Part B — Stack docker-compose

Tạo `docker-compose.yml` chạy:

- `prom/prometheus:v2.55` — port 9090.
- `grafana/grafana:11.3.0` — port 3000.
- `prom/node-exporter:v1.8` — port 9100.
- `prom/blackbox-exporter:v0.25` — port 9115.

`prometheus.yml` scrape:

- `node-exporter:9100` mỗi 15s.
- `blackbox` probe `https://example.com` mỗi 30s

File [compose](./docker-compose.yml), chạy bằng `docker compose up -d`

![](./screenshots/prom_up.png)

### Part C — Grafana dashboard

Truy cập `localhost:3000`, tạo dashboard:

![](./screenshots/dashboard.png)

export ra file `json` [dashboard](./day-5-dashboard-1782562693472.json)

### Part D — Alert

Xem tại [đây](alerts.md).

## Khó khăn

## Reference

- [prometheus tutorial](https://prometheus.io/docs/tutorials/getting_started/)
- Em sử dụng AI để tra cứu nhanh những thuật ngữ và syntax chưa biết.

## Self check

- [x] Stack up bằng 1 lệnh.
- [x] Grafana hiển thị metric từ node-exporter.
- [x] Dashboard JSON import lại được trên máy mentor.
