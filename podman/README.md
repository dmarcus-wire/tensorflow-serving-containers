# Podman

## MacOS
```commandline
# from macbook, Podman will run in a VM
# install podman 
brew install podman

# update mac sys preferences to mount VM local vol
sudo systemsetup -setremotelogin on

# set alias IP for podman VM
sudo ifconfig en0 alias 192.168.126.1

# initial the VM
podman machine init

# start the VM
podman machine start

# ssh into VM
podman machine ssh

# change the VM registries.conf to permissive 
sudo sed -i 's/short-name-mode="enforcing"/short-name-mode="permissive"/g' /etc/containers/registries.conf

# create a mount definition
sudo -i 
vi /etc/systemd/system/run-vmhost.automount 
    [Unit]
    Description=Podman VM host automounter
    [Automount]
    Where=/var/vmhost
    DirectoryMode=0755
    [Install]
    WantedBy=multi-user.target

# create an automount definition under /etc/systemd as root and change mode
sudo -i
vi /etc/systemd/run-vmhost.automount
    [Unit]
    Description=Podman VM host mount
    [Mount]
    What={{USERNAME}}@192.168.126.1:/Users/{{USERNAME}}
    Where=/var/vmhost
    Type=fuse.sshfs
    Options=user,uid=1000,gid=1000,allow_other,IdentityFile=/root/.ssh/id_rsa,StrictHostKeyChecking=no,exec
    [Install]
    WantedBy=multi-user.target
chmod 0644 /etc/systemd/run-vmhost.automount

# create the mount dir
mkdir -p  /var/vmhost

# enable automounting 
systemctl enable run-user-vmhost.automount

# set system certificate
ssh-keygen -t rsa

# copy the content of id_rsa.pub to ~/.ssh/authorized_keys file on the Mac host
cat .ssh/id_pub.rsa

# on the mac 
echo <id_pub.rsa token> >> ~/.ssh/authtorized_keys



# check installation
podman info

# search for the tensorflow serving image
podman search docker.io/tensorflow/serving 

# pull the image
podman pull docker.io/tensorflow/serving 

# list the image
podman images

# run the model 
podman run -t --rm -p 8501:8501 \
--mount type=bind,source="$(pwd)/models",target=/models/ tensorflow/serving \
--model_config_file=/models/models.config \
--model_config_file_poll_wait_seconds=60 \
--allow_version_labels_for_unavailable_models=true
```

# References
- https://www.linkedin.com/pulse/podman-installation-macos-vikas-sharma/
- https://medium.com/intuit-engineering/how-to-getting-podman-to-correctly-mount-a-native-folder-on-a-mac-73eb2a4ee317a