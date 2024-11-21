FROM pytorch/pytorch
RUN apt update && apt install -y iputils-ping net-tools openssh-client vim

#RUN pip install torch --upgrade

COPY run.py /workspace/run.py
COPY run1.py /workspace/run1.py

EXPOSE 1234

ENTRYPOINT ["/bin/bash"]
