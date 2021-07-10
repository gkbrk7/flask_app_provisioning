# flask_app_provisioning
A simple flask app provisioning by Vagrant and its deployment on gunicorn

# Preparation (Creating Server and Installing Dependencies)
> Connect to virtual machine first for example amazon ec2 instance or azure virtual machine via ssh
```
ssh -i {ssh_key.pem} {Username}@{RemoteIpAddress}
```
> Before install python flask dependencies. Update all the mirrors for linux machine. After install all dependencies.
```
sudo apt update
sudo apt install python-pip python-dev nginx
```
> Install legacy python packages for server side dependency control
```
sudo pip install virtualenv
```
> Create directory to work on it
```
mkdir ~/flask_app
cd ~/flask_app
```
> Create virtual environment to keep a track of what python dependencies
```
virtualenv flaskapp_env
```
> Refresh environment for created virtualenv file directory. Activate virtualenv for all dependencies
```
source flaskapp_env/bin/activate
```

# Flask App Installation & Gunicorn Configuration




# Flask App Provisioning


# Flask App Deployment


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