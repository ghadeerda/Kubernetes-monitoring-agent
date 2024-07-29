FROM python:3.9-slim

WORKDIR /usr/src/app

COPY ./monitoring_agent .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "./model_agent.py"]
