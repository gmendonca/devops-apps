FROM ubuntu:trusty

RUN apt-get update -y
RUN apt-get install -y python-pip python-dev build-essential

COPY . /python-app
WORKDIR /python-app

RUN pip install -r requirements.txt

EXPOSE 5000

ENTRYPOINT ["python"]
CMD ["web.py"]
