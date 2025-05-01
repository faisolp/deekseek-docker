# รีสตาร์ท Colima แบบสมบูรณ์
colima stop
colima start --cpu 4 --memory 12 --disk 30 --vm-type=vz --mount-type=virtiofs --arch aarch64

# แก้ไขการเชื่อมต่อโดยตรง
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -a -q) 2>/dev/null || true
docker-compose down

# ลบ containers และ networks ที่เกี่ยวข้อง
docker network prune -f
docker system prune -f

# ตรวจสอบสถานะ Docker socket
ls -la ~/.colima/default/docker.sock
docker context use colima

# รันระบบใหม่
docker-compose up -d