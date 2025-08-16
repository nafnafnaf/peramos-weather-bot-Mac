FROM python:3.11-slim

WORKDIR /app

# Install build dependencies for psutil and timezone data
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set timezone to Athens
ENV TZ=Europe/Athens
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

ENV PYTHONUNBUFFERED=1

CMD ["python", "app.py"]