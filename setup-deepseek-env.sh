#!/bin/bash

# สคริปต์ติดตั้ง DeepSeek-R1 โดยใช้ค่าจาก .env file
# วิธีใช้: ./setup-deepseek-env.sh

# โหลด environment variables
source .env

# สีสำหรับข้อความ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}ติดตั้ง ${MODEL_NAME} บน MacBook Pro + Colima${NC}"
echo -e "${BLUE}======================================================${NC}"

# ตรวจสอบว่า Colima และ Docker ทำงานอยู่หรือไม่
if ! docker ps &>/dev/null; then
  echo -e "${RED}❌ Docker ไม่สามารถเชื่อมต่อได้${NC}"
  echo -e "${YELLOW}🔄 กำลังรีสตาร์ท Colima...${NC}"
  
  colima stop &>/dev/null
  sleep 5
  colima start --cpu ${COLIMA_CPU} --memory ${COLIMA_MEMORY} --disk ${COLIMA_DISK} --vm-type=vz --mount-type=virtiofs --arch aarch64
  
  # รอให้ Docker เชื่อมต่อได้
  echo -e "${BLUE}⏳ รอให้ Docker เชื่อมต่อได้...${NC}"
  for i in {1..10}; do
    if docker ps &>/dev/null; then
      echo -e "${GREEN}✅ Docker เชื่อมต่อได้แล้ว${NC}"
      break
    fi
    if [ $i -eq 10 ]; then
      echo -e "${RED}❌ ไม่สามารถเชื่อมต่อกับ Docker ได้${NC}"
      exit 1
    fi
    echo -n "."
    sleep 3
  done
else
  echo -e "${GREEN}✅ Docker เชื่อมต่อได้${NC}"
fi

# สร้าง Modelfile โดยใช้สคริปต์ gen-modelfile.sh
echo -e "${BLUE}📝 กำลังสร้าง Modelfile...${NC}"
./gen-modelfile.sh

# หยุดการทำงานของ containers ที่มีอยู่
echo -e "${BLUE}🛑 กำลังหยุด containers ที่ทำงานอยู่...${NC}"
docker stop $(docker ps -q) 2>/dev/null || true
docker-compose down 2>/dev/null || true

# ล้าง containers และ networks ที่เกี่ยวข้อง
echo -e "${BLUE}🧹 กำลังล้าง containers และ networks ที่ไม่ได้ใช้...${NC}"
docker network prune -f &>/dev/null
docker system prune -f &>/dev/null

# ตรวจสอบ Docker context
echo -e "${BLUE}🔍 กำลังตรวจสอบ Docker context...${NC}"
docker context use colima &>/dev/null

# สร้างโฟลเดอร์ที่จำเป็น
echo -e "${BLUE}📁 กำลังสร้างโฟลเดอร์...${NC}"
mkdir -p ollama openwebui/data
echo -e "${GREEN}✅ สร้างโฟลเดอร์เรียบร้อย${NC}"

# เริ่มต้น Ollama container
echo -e "${BLUE}🚀 กำลังเริ่ม Ollama...${NC}"
docker-compose up -d ollama

# รอให้ Ollama พร้อมใช้งาน
echo -e "${BLUE}⏳ รอให้ Ollama พร้อมใช้งาน...${NC}"
sleep 15

# แสดงรายการโมเดลที่มีใน Ollama
echo -e "${BLUE}📋 กำลังแสดงรายการโมเดลที่มีใน Ollama...${NC}"
docker exec -it ollama-service ollama list

# ดาวน์โหลดโมเดล DeepSeek-R1
echo -e "${BLUE}📥 กำลังดาวน์โหลดโมเดล ${MODEL_NAME}...${NC}"
echo -e "${YELLOW}⚠️ อาจใช้เวลา 5-15 นาที ขึ้นอยู่กับขนาดโมเดลและความเร็วอินเทอร์เน็ต${NC}"
docker exec -it ollama-service ollama pull ${MODEL_NAME}

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ ดาวน์โหลดโมเดลเรียบร้อย${NC}"
  
  # สร้างโมเดลที่ปรับแต่งแล้วสำหรับภาษาไทย
  echo -e "${BLUE}🔧 กำลังสร้างโมเดลที่ปรับแต่งแล้ว (${MODEL_ALIAS})...${NC}"
  docker cp models/Modelfile.deepseek-r1 ollama-service:/tmp/Modelfile
  docker exec -it ollama-service ollama create ${MODEL_ALIAS} -f /tmp/Modelfile
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ สร้างโมเดลที่ปรับแต่งแล้ว (${MODEL_ALIAS}) เรียบร้อย${NC}"
  else
    echo -e "${RED}❌ ไม่สามารถสร้างโมเดลที่ปรับแต่งได้${NC}"
    echo -e "${YELLOW}⚠️ จะใช้โมเดลต้นฉบับแทน${NC}"
    MODEL_ALIAS=$MODEL_NAME
  fi
else
  echo -e "${RED}❌ ไม่สามารถดาวน์โหลดโมเดล ${MODEL_NAME} ได้${NC}"
  exit 1
fi

# เริ่ม WebUI
echo -e "${BLUE}🚀 กำลังเริ่ม OpenWebUI...${NC}"
docker-compose up -d webui
sleep 10

if docker ps | grep -q "openwebui"; then
  echo -e "${GREEN}✅ OpenWebUI ทำงานแล้ว${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo -e "${GREEN}🎉 การติดตั้งเสร็จสมบูรณ์!${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo -e "${GREEN}🌐 เข้าถึง OpenWebUI ได้ที่: ${BLUE}http://localhost:${WEBUI_PORT}${NC}"
  echo -e "${GREEN}👤 ชื่อผู้ใช้: ${BLUE}${WEBUI_USER}${NC}"
  echo -e "${GREEN}🔑 รหัสผ่าน: ${BLUE}${WEBUI_PASS}${NC}"
  echo -e "${GREEN}🤖 โมเดลที่ใช้: ${BLUE}${MODEL_ALIAS}${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo -e "${YELLOW}📌 คำแนะนำการใช้งาน:${NC}"
  echo -e "  1. หลังจากล็อกอิน เลือกโมเดล '${MODEL_ALIAS}' จากรายการ"
  echo -e "  2. สามารถทดสอบความสามารถในการใช้ภาษาไทยได้ทันที"
  echo -e "  3. ตั้งค่า temperature ระหว่าง ${MODEL_TEMPERATURE} เพื่อความสมดุลระหว่างความแม่นยำและความคิดสร้างสรรค์"
  echo -e "${BLUE}======================================================${NC}"
else
  echo -e "${RED}❌ OpenWebUI ไม่ได้ทำงาน${NC}"
  echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs openwebui${NC}"
fi

exit 0