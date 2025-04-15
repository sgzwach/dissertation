FROM python:3.10-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY verify.py .

ENTRYPOINT ["/usr/local/bin/python", "verify.py"]