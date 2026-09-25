# syntax=docker/dockerfile:1

# ---------- Base image ----------
FROM python:3.11-slim AS base

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install OS dependencies (if any) and uv (the Python package manager)
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    pip install --no-cache-dir uv && \
    rm -rf /var/lib/apt/lists/*

# Add uv to PATH (the installer puts it in /root/.cargo/bin)
ENV PATH="/root/.cargo/bin:${PATH}"

# ---------- Builder stage ----------
FROM base AS builder
WORKDIR /app

# Copy project metadata first (pyproject and lock) to leverage Docker cache
COPY pyproject.toml uv.lock ./

# Install the project and its dependencies in a virtual environment
RUN uv venv .venv && \
    uv sync --frozen

# ---------- Runtime stage ----------
FROM base AS runtime
WORKDIR /app

# Copy the installed virtual environment from the builder
COPY --from=builder /app/.venv .venv

# Copy the rest of the source code
COPY . .

# Ensure uv is still on PATH (it already is from the base image)
ENV PATH="/root/.cargo/bin:${PATH}"

# Expose the FastAPI port (default used by the application)
EXPOSE 8000

# Use the virtual environment's Python interpreter to run the app
ENTRYPOINT ["/app/.venv/bin/uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
