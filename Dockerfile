FROM pytorch/pytorch
RUN apt update && apt install -y iputils-ping net-tools openssh-client vim

COPY run.py /workspace/run.py
COPY layout-up /workspace/layout-up
COPY layout-down /workspace/layout-down

RUN mkdir /logs

ENTRYPOINT ["/bin/bash"]
