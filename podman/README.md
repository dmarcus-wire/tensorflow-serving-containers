# Podman

## Steps

```commandline
# confirm current root directory setting for the containers
podman info | grep -i root

# create a local mount directory for the container to access the models
sudo mkdir -p /data/containers

# check the SELinux context (expected unconfined_u:object_r:default_t)
ls -ldZ /data && ls -ldZ /data/containers/

# Update the setting and change the directory to one created above.
sudo vi /etc/containers/storage.conf
    # Primary Read/Write location of container storage
    #graphroot = "/var/lib/containers/storage"
    graphroot = "/data/containers"

# clone in the project files from github
cd /data/containers && sudo git clone https://github.com/dmarcus-wire/tensorflow-serving-containers.git

# correct SELinux Labels for the directory /data/containers
sudo semanage fcontext -a -e /var/lib/containers /data/containers
sudo restorecon -R -vv /data/containers

# Confirm if type has been set (expected unconfined_u:object_r:container_var_lib_t)
ls -dZ /data/containers/

# search for the tensorflow serving image
podman search --format "table {{.Index}} {{.Name}}" docker.io/tensorflow/serving

# pull the image
podman pull docker.io/tensorflow/serving:latest

# list the image
podman images

# test the container image with a model
podman run --rm -d --name tfserving_base tensorflow/serving

# run the container from the "podman" subfolder
sudo podman run -d -p 8501:8501 \
--name animal_predict \
-v "$(pwd)"/models:/models \
tensorflow/serving \
--model_config_file=/models/models.config \
--model_config_file_poll_wait_seconds=60 \
--allow_version_labels_for_unavailable_models=true

--mount type=bind,source="$(pwd)/models",target=/models/ tensorflow/serving \
--model_config_file=/models/models.config \
--model_config_file_poll_wait_seconds=60 \
--allow_version_labels_for_unavailable_models=true

# access the container and check the mount
podman exec -it tfserving_base_mounted /bin/bash
    # check the directory structure
    ls -l
    # check entrypoint user
    whoami
    # exit
    exit

# copy the models directory contents to the container
podman cp models/. tfserving_base:/models

# commit the container that's serving your model by changing MODEL_NAME to match your model's name
podman commit tfserving_base animal_model:v1 -a "dmarcus@redhat.com" -m "initial commit of rootful tfserving model" -f docker

# test the container mounted to the data directory created
podman run -d --name animal \
-p 8501:8501 \
-v /data/containers/tensorflow-serving-containers/podman/models:/models \
localhost/animal_model:v1 

# test the container mounted to the data directory created
podman run -d --name animal \
-p 8501:8501 \
localhost/animal_model:v1 \
--model_config_file=/models/models.config \
--model_config_file_poll_wait_seconds=60 \
--allow_version_labels_for_unavailable_models=true


# kill the base model
podman kill serving_base

# This will leave you with a Docker image called <my container> that you can deploy and will load your model for serving on startup.

# run the TensorFlow Serving container pointing it to this model and opening the REST API port (8501):
```

## Podman Setup

```commandline
# check for container-tools module
yum module list

# check packages
yum module info container-tools

# yum module install container tools
sudo yum module install -y container-tools policycoreutils-python-utils
```

## MacOS Setup
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
```

# References
- https://www.linkedin.com/pulse/podman-installation-macos-vikas-sharma/
- https://medium.com/intuit-engineering/how-to-getting-podman-to-correctly-mount-a-native-folder-on-a-mac-73eb2a4ee317a
- https://computingforgeeks.com/set-selinux-context-label-for-podman-graphroot-directory/