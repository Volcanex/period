FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8080

WORKDIR /app

# Install deps first so this layer caches across source edits.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Run as a non-root user. UID 1000 typically matches the host dev user,
# which keeps volume-mounted file ownership sane.
RUN useradd --uid 1000 --create-home --shell /bin/sh period \
 && chown period:period /app

COPY --chown=period:period . .
RUN chmod +x scripts/entrypoint.sh

USER period

EXPOSE 8080

# Start the backend API.
ENTRYPOINT ["scripts/entrypoint.sh"]
