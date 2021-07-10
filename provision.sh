#!/bin/bash

APPNAME=flaskapp
SERVER_IP=$(ip a | grep inet | grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | tail -n 2 | head -n 1)

step=1
step() {
    echo "Step $step $1"
    step=$((step+1))
}

install_dependencies(){
    step "===== Installing python and nginx ====="
    sudo apt-get update -qq
    sudo apt-get install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools -y
}

install_virtualenv(){
    step "===== Installing virtualenv ====="
    sudo apt-get install python3-venv
}

update_python3_6(){
    step "===== Updating python version to 3.6 ====="
    sudo apt-get install build-essential checkinstall -y
    sudo apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev -y
    wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tar.xz
    tar xvf Python-3.6.0.tar.xz
    cd Python-3.6.0/
    ./configure
    sudo make altinstall
    cd ..
}

create_project_directories(){
    step "===== Creating project directories ====="
    mkdir ${APPNAME} && cd ${APPNAME}
    sudo chown -R vagrant:vagrant /home/vagrant/${APPNAME}
}

activate_virtualenv(){
    step "===== Activating virtualenv ====="
    python3.6 -m venv ${APPNAME}env
    source ${APPNAME}env/bin/activate
}

configure_flask(){
    step "===== Configuring flask and gunicorn ====="
    pip install wheel
    pip install gunicorn flask
    cat >> ${APPNAME}.py <<EOL
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello My name is Gokberk YILDIRIM. <br> I am DevOps and Linux Lover... ♥</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOL
}

firewall_setup(){
    step "===== Opening port 5000 on firewall ====="
    sudo ufw allow 5000
}

configure_gunicorn(){
    step "===== Configuring gunicorn server ====="
    cat >> wsgi.py <<EOL
from ${APPNAME} import app

if __name__ == "__main__":
    app.run()
EOL
    gunicorn -D --bind 0.0.0.0:5000 wsgi:app
    pkill gunicorn
    deactivate
}

create_service(){
    step "===== Creating ${APPNAME} service on systemd ====="
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
}

configure_nginx(){
    step "===== Installing and Configuring nginx ====="
    sudo apt-get install nginx -y
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
}

start_app(){
    step "===== Application started ====="
    echo -e "Application ${APPNAME} started on ${SERVER_IP}..."
    echo -e "Application ${APPNAME} started on http://flaskapp.local"
    echo -e "Application ${APPNAME} started on localhost:8080"
    # FLASK_APP=${APPNAME}.py flask run
}

main() {
    echo "===== Provisioning started ====="
    install_dependencies
    install_virtualenv
    update_python3_6
    create_project_directories
    activate_virtualenv
    configure_flask
    firewall_setup
    configure_gunicorn
    create_service
    configure_nginx
    start_app
}

main