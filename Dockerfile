FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y wget python3 pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip install torch==2.1.1
#RUN pip install torch==2.1.1 --index-url https://download.pytorch.org/whl/cpu
RUN apt update && apt install -y iputils-ping
RUN apt install -y net-tools
RUN pip install numpy

COPY run.py /run.py
COPY run1.py /run1.py

RUN apt install -y openssh-client

EXPOSE 1234

RUN apt install -y vim

ENTRYPOINT ["/bin/bash"]
