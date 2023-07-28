#!/bin/bash

rm -Rf /var/www/html/*;
echo "<html><body><h1>$NAME</h1><p>Mon super site</p></body></html>" > /var/www/html/index.html;

if [ "$NAME" = "web2" ]; then
    ssh-keyscan web1 >> /root/.ssh/known_hosts;
    echo "*/5 * * * * rsync -avz -e ssh /var/www/html/* root@web1:/var/www/html/." > /etc/cron.d/rsync;
    crontab /etc/cron.d/rsync;
    service cron start;
fi

service cron start;
service ssh start;
nginx -g "daemon off;"
tail -f /dev/null;