docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm dmz1
docker network rm dmz2

docker network create --subnet 192.168.10.0/24 -d bridge dmz1
docker network create --subnet 192.168.20.0/24 -d bridge dmz2

docker run -dit --name web1 nginx
docker run -dit --name web2 nginx
docker run -dit --name loadbalancer -p 80:80 -p 443:443 nginx
# docker run -dit --name bdd mysql

docker network disconnect bridge web1
docker network disconnect bridge web2
# docker network disconnect bridge bdd

docker network connect dmz1 loadbalancer --ip 192.168.10.5
docker network connect dmz1 web1 --ip 192.168.10.10
docker network connect dmz1 web2 --ip 192.168.10.11
docker network connect dmz2 web1 --ip 192.168.20.10
docker network connect dmz2 web2 --ip 192.168.20.11
# docker network connect dmz2 bdd --ip 192.168.20.8

docker exec -it web1 bash -c "echo '<h1>Web1</h1>' > /usr/share/nginx/html/index.html"
docker exec -it web2 bash -c "echo '<h1>Web2</h1>' > /usr/share/nginx/html/index.html"

# load balancer
docker exec -it loadbalancer bash -c "apt update -y"
# docker exec -it loadbalancer bash -c "apt install -y nano"
docker exec -it loadbalancer bash -c "rm -Rf /etc/nginx/conf.d/default.conf"

## load balance site conf
docker exec -it loadbalancer bash -c "echo '
upstream backend {
    least_conn;

    server 192.168.10.10:80;
    server 192.168.10.11:80;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend;
    }
}
' > /etc/nginx/conf.d/loadbalancer.conf"

docker exec -it loadbalancer bash -c "nginx -t"

## SSL conf
docker exec -it loadbalancer bash -c "apt install -y openssl"
docker exec -it loadbalancer bash -c "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/conf.d/loadbalancer.key -out /etc/nginx/conf.d/loadbalancer.crt -subj '/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=loadbalancer'"
docker exec -it loadbalancer bash -c "echo '
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/conf.d/loadbalancer.crt;
    ssl_certificate_key /etc/nginx/conf.d/loadbalancer.key;

    location / {
        proxy_pass http://backend;
    }
}

' >> /etc/nginx/conf.d/loadbalancer.conf"

docker exec -it loadbalancer bash -c "nginx -t"

docker exec -it loadbalancer bash -c "nginx -s reload"

## Install openssh on web1 and web2
docker exec -it web1 bash -c "apt update -y"
docker exec -it web1 bash -c "apt install -y openssh-server"
docker exec -it web1 bash -c "mkdir -p /home/www-data/.ssh"
docker exec -it web1 bash -c "service ssh start"

docker exec -it web2 bash -c "apt update -y"
docker exec -it web2 bash -c "apt install -y openssh-server"
docker exec -it web2 bash -c "service ssh start"

## create an ssh key on web2 (ed25519) and copy it to web1, using .ssh/authorized_keys file
docker exec -it web2 bash -c "ssh-keygen -t ed25519 -f /home/www-data/.ssh/id_ed25519 -q -N ''"
docker exec -it web2 bash -c 'cat /home/www-data/.ssh/id_ed25519.pub' | echo "$(cat -)"

## desacgtivate root login, no password, and connection without key with ssh on web1 and web2
docker exec -it web1 bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config"
docker exec -it web1 bash -c "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
docker exec -it web1 bash -c "sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
docker exec -it web1 bash -c "service ssh restart"

docker exec -it web2 bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config"
docker exec -it web2 bash -c "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
docker exec -it web2 bash -c "sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
docker exec -it web2 bash -c "service ssh restart"

## create a crontab on web2 to rsync html folder from web1 to web2 every 5 minute
docker exec -it web2 bash -c "echo '*/5 * * * * rsync -avz -e \"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\" www-data@192.168.10.10:/usr/share/nginx/html/ /usr/share/nginx/html/' > /etc/crontab"