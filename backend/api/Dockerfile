FROM python:3.10-slim

WORKDIR /app

# Copy package files
COPY pyproject.toml ./
COPY src/ src/

# Install the package
RUN pip install --no-cache-dir .

# Expose API port
EXPOSE 8000

# Run the application
CMD ["python", "-m", "vfs_api", "--verbose", "--host", "0.0.0.0", "--port", "8000"]