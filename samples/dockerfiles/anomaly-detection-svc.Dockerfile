# anomaly-detection-svc Dockerfile — Multi-stage, distroless Python
# Day 14 Deliverable | Author: Aditi Sharma | Date: 12 July 2026

# ── Stage 1: Builder ──────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies into a target directory
# (so we can copy only the installed packages into the runtime stage)
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/build/packages -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Non-root user
RUN useradd --uid 1000 --no-create-home --shell /bin/false appuser

# Copy installed packages from builder
COPY --from=builder /build/packages /usr/local/lib/python3.11/site-packages/

# Copy application source
COPY --chown=1000:1000 src/ src/

LABEL org.opencontainers.image.title="anomaly-detection-svc"
LABEL org.opencontainers.image.vendor="ShieldPay Financial Services"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

USER 1000

EXPOSE 8080 8081

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8081/healthz')"]

# Warm-up happens at startup inside the FastAPI lifespan event
# (models loaded into memory before the first request)
ENTRYPOINT ["python", "-m", "uvicorn", \
  "src.main:app", \
  "--host", "0.0.0.0", \
  "--port", "8080", \
  "--workers", "1"]
