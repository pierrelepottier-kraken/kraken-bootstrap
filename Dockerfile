FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --no-compile -r requirements.txt

RUN useradd --uid 1000 --user-group --create-home app \
    && mkdir -p /app/output \
    && chown app:app /app/output

COPY . .

USER app

CMD ["python", "-m", "app.main"]
