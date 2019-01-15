# CVP-in-Docker

When booting for the first time CVP initializes a lot of the processes which consumes a lot of time and RAM. During subsequent boots, CVP needs much less RAM and initializes a lot quicker. The goal of this doc is to produce the fully initialized CVP image that can be run locally for testing and development purposes (with as little as 8G of RAM!).

> Note: Simple `build->run->commit` path would not work as the image size will double (qcow2 file is different before and after the first run). So in order to keep the image size small we'll squash all layers into one by doing `import|export` on it.

## Procedure

1. Assuming cvp image and tools archives are in the $pwd, run
```bash
docker build . -t cvp:2018.2.2-init --build-arg IMAGE=cvp-2018.2.2-kvm.tgz
```

2. Run the CVP VM the first time (can take up to 15 minutes)

```bash
docker run -d --privileged --cidfile cidfile --name cvp cvp:2018.2.2-init
```

3. Make sure CVP is fully initialised 
```bash
docker exec -it cvp bash
virsh console cvp
cvp login: root
Password: 
[root@cvp ~]# su cvp
[cvp@cvp root]$ cvpi status all 
```

4. Once verified, shutdown the VM

```bash
[root@cvp ~]# shutdown now
```
5. From the host OS squash the current image

```bash
docker export $(cat cidfile) | docker import - cvp:2018.2.2
docker rm -f cvp
```

6. (Optionally) Save image into a file

```
docker save cvp:2018.2.2 -o cvp:2018.2.2.docker
```

## Using CVP image

To run it with 8192MB of RAM do:

```bash

docker run -d --privileged -p 443:443  -p 9910:9910 --name cvp --entrypoint ./entrypoint.sh cvp:2018.2.2 8192
```

> To register devices with CVP, PRIMARY_DEVICE_INTF_IP in /etc/cvpi/env should be modified to the public IP address followed by `cvpi stop cvp`, `cvpi start cvp`

> `docker save|load` may require docker version > 18.09 due to https://github.com/moby/moby/issues/37581
