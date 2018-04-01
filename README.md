# infiniticg-project
This project is intended for demo purposes.
Here is the requirements

Then here are a few points about the solution
- This code is wrriten in terraform, so user needs to download and set up terraform.
- Code was built on Linux rhel 7.x , though this should not matter.
- Web tier (auto scaling group for HA and elasticity) uses linux rhel 7.4 and httpd/apache server.
- User needs to edit vars.tvar with his own vpc and subnet info etc..
- Solution makes use of EFS and auto mounts targets into ec2 so that web-content is separated from web server (resiliancy).  However, efs is not mounted into ec2 (code commented out) because of what appears like a race condition that makes resolving efs dns name fail on first attempt (It succeeds on follow up events).  Therefore, content is loaded into /var/www/html/index.html on ec2
Solution uses ELB.  However, I would use ALB if I had to do another release as ALB is better suited for http traffic.
