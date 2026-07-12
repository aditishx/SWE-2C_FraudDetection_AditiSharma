# rule-engine-svc Dockerfile — Multi-stage, distroless
# Day 14 Deliverable | Author: Aditi Sharma | Date: 12 July 2026
#
# Multi-stage build:
#   Stage 1 (builder): compile Java source → fat JAR
#   Stage 2 (runtime): distroless JRE — no shell, no package manager
#                      minimal attack surface for PCI DSS compliance

# ── Stage 1: Builder ──────────────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /build

# Copy dependency manifest first — Docker layer cache means dependencies
# are only re-downloaded when pom.xml changes, not on every source change
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copy source and build
COPY src/ src/
RUN mvn package -DskipTests -q

# ── Stage 2: Runtime ──────────────────────────────────────────────────────
# gcr.io/distroless/java21: no shell, no curl, no apt — nothing to exploit
FROM gcr.io/distroless/java21-debian12:nonroot

WORKDIR /app

# Non-root user (UID 1000) — PCI DSS and general security hygiene
# "nonroot" variant of distroless already runs as UID 65532;
# we override to 1000 to match Kubernetes SecurityContext expectations
USER 1000

# Copy only the compiled JAR from the builder stage (not source code)
COPY --from=builder /build/target/rule-engine-svc-*.jar app.jar

# Metadata labels for image tracking
LABEL org.opencontainers.image.title="rule-engine-svc"
LABEL org.opencontainers.image.vendor="ShieldPay Financial Services"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

# Service listens on 8080 (gRPC) and 8081 (management/health)
EXPOSE 8080 8081

# Health check — Kubernetes liveness/readiness probes call this endpoint
# Distroless has no wget/curl, so we use the Java-native health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
  CMD ["java", "-cp", "app.jar", "com.shieldpay.health.HealthCheck"]

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
