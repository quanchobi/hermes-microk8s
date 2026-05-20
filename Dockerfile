FROM ubuntu:24.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
