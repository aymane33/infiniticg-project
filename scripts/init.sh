#!/bin/bash
 yum install -y httpd
 systemctl start httpd
 echo "<Center><H1>To InfinitiCG and Beyond</H1></Center>" > /var/www/html/index.html
chmod 755 /var/www/html/index.html