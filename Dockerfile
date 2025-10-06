# BUILD STAGE
# Use Python 3.12 base image
FROM python:3.12 AS builder

# Install uv package manager
RUN pip install --no-cache-dir uv

# Set working directory
WORKDIR /app

# Copy pyproject.toml
COPY pyproject.toml ./
COPY README.md ./
COPY cc_simple_server/ ./cc_simple_server/

# Install Python dependencies using uv into a virtual environment
RUN uv venv && \
    uv sync

# FINAL STAGE
# Use Python 3.12-slim base image (smaller footprint)
FROM python:3.12-slim

# Copy the virtual environment from build stage
COPY --from=builder /app/.venv /app/.venv

# Set environment variables
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Copy application source code
COPY cc_simple_server/ ./cc_simple_server/
COPY tests/ ./tests/

# Create non-root user for security
RUN useradd -m appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]