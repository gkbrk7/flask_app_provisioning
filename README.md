# flask_app_provisioning
A simple flask app provisioning by Vagrant and its deployment on gunicorn

# Quickstart
> Install virtualbox and vagrant cli according to OS. After installation of necessary files, just run below command: 
```
vagrant up
```
> If you want to destroy all resources run,
```
vagrant destroy -f
```
# Preparation (Creating Server and Installing Dependencies)
> Connect to virtual machine first for example amazon ec2 instance or azure virtual machine via ssh
```bash
ssh -i {ssh_key.pem} {Username}@{RemoteIpAddress}
```
> Before install python flask dependencies. Update all the mirrors for linux machine. After install all dependencies.
```bash
sudo apt-get update -qq
sudo apt-get install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools -y
```
> Install legacy python packages for server side dependency control
```bash
sudo apt-get install python3-venv
```
> Update default python version from 3.5.2 to 3.6
```bash
sudo apt-get install build-essential checkinstall -y
sudo apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev -y
wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz
tar xvf Python-3.6.0.tar.xz
cd Python-3.6.0/
./configure
sudo make altinstall
```
> Create directory to work on it and change ownership of this directory. This is very important because we connect web server with socket after web server conf
iguration
```bash
mkdir ${APPNAME} && cd ${APPNAME}
sudo chown -R vagrant:vagrant /home/vagrant/${APPNAME}
```
> Create virtual environment to keep a track of what python dependencies
```bash
python3.6 -m venv ${APPNAME}env
```
> Refresh environment for created virtualenv file directory. Activate virtualenv for all dependencies
```bash
source ${APPNAME}env/bin/activate
```

# Flask App Installation & Gunicorn Configuration
> Install wheel with the local instance of pip to ensure that our packages will install even if they are missing.
> Install gunicorn and flask after wheel
```bash
pip install wheel
pip install gunicorn flask
```
> Create a sample app and expose 5000 port to stream website on gunicorn and configure firewall settings with respect to 5000 port
```bash
    cat >> ${APPNAME}.py <<EOL
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello My name is Gokberk YILDIRIM. <br> I am DevOps and Linux Lover... ♥</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOL
sudo ufw allow 5000
```

# Flask App Provisioning
> Provide wsgi.py file that will serve as the entry point for our application. This will tell our Gunicorn server how to interact with the application. After bind gunicorn settings to wsgi app as an deamon mode. Due to testing, delete all gunicorn process and deactivate the environment.
```bash
cat >> wsgi.py <<EOL
from ${APPNAME} import app

if __name__ == "__main__":
    app.run()
EOL
gunicorn -D --bind 0.0.0.0:5000 wsgi:app
pkill gunicorn
deactivate
```

# Flask App Deployment
> We want to expose the flask app as a service on linux and configure as a reverse proxy with the nginx to reach the website. After configuration of service start service with systemctl and enable it.
```bash
    cat >> /etc/systemd/system/${APPNAME}.service <<EOL
[Unit]
Description=Gunicorn instance to serve ${APPNAME}
After=network.target

[Service]
User=vagrant
Group=www-data
WorkingDirectory=/home/vagrant/${APPNAME}
Environment="PATH=/home/vagrant/${APPNAME}/${APPNAME}env/bin"
ExecStart=/home/vagrant/${APPNAME}/${APPNAME}env/bin/gunicorn --workers 3 --bind unix:${APPNAME}.sock -m 007 wsgi:app

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl start ${APPNAME}
sudo systemctl enable ${APPNAME}
```
> Lastly, configure nginx as a reverse web proxy to hande flask app request and send it to gunicorn server. Create symbolic link between application in nginx sites-available directory and nginx enabled websites. After these configuration delete allow 5000 port on firewall and allow nginx.
```bash
sudo cat >> /etc/nginx/sites-available/${APPNAME} <<EOL
server {
    listen 80;
    server_name ${SERVER_IP} flaskapp.local www.flaskapp.local;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/vagrant/${APPNAME}/${APPNAME}.sock;
    }
}
EOL
sudo ln -s /etc/nginx/sites-available/${APPNAME} /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
sudo ufw delete allow 5000
sudo ufw allow 'Nginx Full'
```
> Now, you are ready to reveal flask app website on defined private guest ip address in the local OS or environment. For example, 
```bash
curl 192.168.2.15
``` 
> You will be seeing that the flask app is running on port 80 with the nginx. That means nginx works healthy and gunicorn serves the website properly.

# Additional Configuration
- Windows
> If you want to work with domain name in the local environment, just run `DomainConfiguration.ps1` powershell script. Open powershell and execute below command:
```
Powershell.exe -executionpolicy remotesigned -File  "DomainConfiguration.ps1"
```
- Linux
> Open /etc/hosts file and add below line at the end of the file:
```
echo "192.168.2.15  flaskapp.local www.flaskapp.local" >> /etc/hosts
```