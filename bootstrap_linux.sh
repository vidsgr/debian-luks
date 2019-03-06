rm netdebian-stable-amd64.*gz
~/workspace/debos/debos-docker/docker/run.sh ./debootstrap.auto.yaml
~/workspace/debos/debos-docker/docker/run.sh ./luks.auto.yaml
