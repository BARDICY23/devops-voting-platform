ARG BUILD_VERSION=unknown
ARG GIT_COMMIT_SHA=unknown
ARG REPO_URL=https://github.com/BARDICY23/devops-voting-app

FROM python:3.11-slim

# Create non-root user
RUN useradd -m appuser

WORKDIR /app

# Install system deps for some Python packages if needed
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Copy only requirements first for Docker layer caching
COPY requirements.txt .

# Install Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Fix permissions and switch to non-root
RUN chown -R appuser:appuser /app
USER appuser

# Expose the port expected by the challenge
EXPOSE 8080

LABEL org.opencontainers.image.title="Voting App Vote Service (Python/Flask)" \
      org.opencontainers.image.version=$BUILD_VERSION \
      org.opencontainers.image.revision=$GIT_COMMIT_SHA \
      org.opencontainers.image.source=$REPO_URL

# Run the Flask app (app.py should bind to 0.0.0.0:8080)
CMD ["python", "app.py"]
