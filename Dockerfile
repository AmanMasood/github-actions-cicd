FROM python:3.12-slim
ARG APP_VERSION=dev
ARG GIT_SHA=unknown
ENV PYTHONUNBUFFERED=1 APP_VERSION=${APP_VERSION} GIT_SHA=${GIT_SHA}
RUN useradd --system --create-home app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src ./src
USER app
EXPOSE 8000
HEALTHCHECK CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "2", "src.app:app"]
