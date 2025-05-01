
colima start --cpu 4 --memory 4 --disk 100 --vm-type=vz --mount-type=virtiofs --arch aarch64

# ตรวจสอบสถานะ Docker socket
ls -la ~/.colima/default/docker.sock
docker context use colima
