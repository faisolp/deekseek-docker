#!/bin/bash
# รีสตาร์ท Colima โดยใช้ค่าจาก .env
# วิธีใช้: ./colima-restart.sh

# โหลด environment variables
source .env

# สีสำหรับข้อความ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}กำลังรีสตาร์ท Colima สำหรับ ${MODEL_NAME}${NC}"
echo -e "${BLUE}======================================================${NC}"

# รีสตาร์ท Colima ด้วยค่าจาก .env
echo -e "${YELLOW}กำลังหยุด Colima...${NC}"
colima stop

echo -e "${GREEN}กำลังเริ่ม Colima ด้วยค่าที่กำหนด:${NC}"
echo -e "   CPU: ${COLIMA_CPU}"
echo -e "   Memory: ${COLIMA_MEMORY}GB"
echo -e "   Disk: ${COLIMA_DISK}GB"

colima start --cpu ${COLIMA_CPU} --memory ${COLIMA_MEMORY} --disk ${COLIMA_DISK} --vm-type=vz --mount-type=virtiofs --arch aarch64

# ตรวจสอบสถานะ Docker socket
ls -la ~/.colima/default/docker.sock
docker context use colima

echo -e "${GREEN}✅ Colima รีสตาร์ทเรียบร้อย พร้อมใช้งานสำหรับ ${MODEL_NAME}${NC}"