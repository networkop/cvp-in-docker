# CVP-in-Docker

When booting for the first time CVP initializes a lot of the processes which consumes a lot of time and RAM. During subsequent boots, CVP needs much less RAM and initializes a lot quicker. The goal of this doc is to produce the fully initialized CVP image that can be run locally for testing and development purposes (with as little as 8G of RAM!).

## Procedure

1. Assuming cvp image and tools archives are in the $pwd, run
```bash
docker build . -t cvp:2018.2.4-init --build-arg IMAGE=cvp-2018.2.4-kvm.tgz  --build-arg TOOLS=cvp-tools-2018.2.4.tgz
```

2. Run the CVP VM the first time (can take up to 15 minutes)

```bash
docker run -d --privileged --name cvp cvp:2018.2.4-init
```

3. Make sure CVP is fully initialised 
```bash
docker exec -it cvp bash
virsh console cvp
cvp login: root
Password: 
[root@cvp ~]# su cvp
cvp@cvp root]$ cvpi status all

Current Running Command: None
Executing command. This may take a few seconds...
primary 	123/123 components running
```

4. Once verified, shutdown the VM

```bash
[cvp@cvp root]$ exit
exit
[root@cvp ~]# shutdown now
```
5. From the host OS squash the current image

```bash
docker export cvp | docker import --change "ENTRYPOINT ./entrypoint.sh" - cvp:2018.2.4 
docker rm -f cvp
```

> `docker save|load` may require docker version > 18.09 due to https://github.com/moby/moby/issues/37581

6. (Optionally) Save image into a file

```
docker save cvp:2018.2.4 -o cvp:2018.2.4.docker
```

## Using CVP image

To run it with 8192MB of RAM do:

```bash

docker run -d --privileged -p 443:443  -p 9910:9910 --name cvp cvp:2018.2.4 8192
```

> To register devices with CVP, PRIMARY_DEVICE_INTF_IP in /etc/cvpi/env should be modified to the public IP address followed by `cvpi stop cvp`, `cvpi start cvp`

