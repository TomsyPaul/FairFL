FROM pytorch/pytorch
RUN apt update && apt install -y iputils-ping net-tools openssh-client vim

COPY run.py /workspace/run.py
COPY run1.py /workspace/run1.py

ENTRYPOINT ["/bin/bash"]
