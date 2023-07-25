FROM debian:bullseye
MAINTAINER fabien_colard

RUN apt-get update -y && \
    apt-get install -y nginx openssl openssh-server rsync cron curl nano

# ssh config
RUN mkdir -p /home/www-data/.ssh
COPY key/web.key /root/.ssh/web.key
COPY key/web.key.pub /root/.ssh/web.key.pub
COPY ssh.config /root/.ssh/config
RUN cat /root/.ssh/web.key.pub >> /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/web.key

# authorize ssh connection with root but with key and not with password
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config

COPY entrypoint.sh /root/entrypoint.sh

EXPOSE 22 80

CMD ["bash", "/root/entrypoint.sh"]

# docker compose exec web2 bash -c "curl web1"
# docker compose exec web2 bash -c "rsync -avz /var/www/html/ web1:/var/www/html/"