FROM python:3.12-slim AS build
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
EXPOSE 3000
CMD ["app.py"]
