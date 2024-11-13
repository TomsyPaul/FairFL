FROM ubuntu:22.04
# From https://stackoverflow.com/questions/58269375/how-to-install-packages-with-miniconda-in-dockerfile
#ENV PATH="/root/miniconda3/bin:${PATH}"
#ARG PATH="/root/miniconda3/bin:${PATH}"

# Install wget to fetch Miniconda
RUN apt-get update && \
    apt-get install -y wget python3 pip 

RUN pip install torch==2.1.1


RUN apt update && apt install -y iputils-ping
RUN apt install -y net-tools
RUN pip install numpy

COPY run.py /run.py
COPY run1.py /run1.py

RUN apt install -y openssh-client

EXPOSE 1234

RUN apt install -y vim

ENTRYPOINT ["/bin/bash"]

