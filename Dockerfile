FROM pytorch/pytorch
RUN apt update && apt install -y iputils-ping
RUN apt install -y net-tools

COPY run.py /workspace/run.py
COPY run1.py /workspace/run1.py

RUN apt install -y openssh-client

RUN apt install -y vim

RUN pip install torch==2.4.0

EXPOSE 1234

ENTRYPOINT ["/bin/bash"]
