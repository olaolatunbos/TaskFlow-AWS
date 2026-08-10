# ---- Stage 1: build ----
# An image digest is a unique, immutable identifier for a container image, based on a cryptographic hash of the image's content.
FROM python:3.12-slim@sha256:229a2c5bfa27522db7815ea81f9bed70af17ccb9de9fc7ad142b1877b5830d36 AS build

WORKDIR /app

COPY requirements.txt .

RUN pip install --target=/app/deps --no-cache-dir -r requirements.txt

COPY . .


FROM gcr.io/distroless/python3-debian12

WORKDIR /app

COPY --from=build /app/deps /app/deps

COPY --from=build /app /app

ENV PYTHONPATH=/app/deps

USER 65532:65532

# HEALTHCHECK tells Docker how to determine whether the application inside the container is healthy.
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["app.py"]
