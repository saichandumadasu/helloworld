FROM python:3.12-slim-bookworm AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv 

WORKDIR /app

COPY pyproject.toml ./

RUN uv sync 

FROM python:3.12-slim-bookworm as runner

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app

COPY --from=builder /app /app

COPY . .

EXPOSE 8000

CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
