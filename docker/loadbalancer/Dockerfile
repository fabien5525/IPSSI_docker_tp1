FROM nginx:latest
MAINTAINER fabien_colard

RUN apt-get update -y && apt-get install -y openssl

COPY conf/loadbalancer.conf /etc/nginx/conf.d/loadbalancer.conf
RUN rm /etc/nginx/conf.d/default.conf

run openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/conf.d/loadbalancer.key -out /etc/nginx/conf.d/loadbalancer.crt -subj '/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=loadbalancer'

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]