#!/bin/bash

# สคริปต์สำหรับติดตั้งโมเดลโดยใช้ค่าจาก .env file
# วิธีใช้: ./pull-model.sh

# โหลด environment variables
source .env

# สีสำหรับข้อความ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}ติดตั้งโมเดล ${MODEL_NAME} จาก Ollama Library${NC}"
echo -e "${BLUE}======================================================${NC}"

# ตรวจสอบว่า Ollama container ทำงานหรือไม่
if ! docker ps | grep -q "ollama-service"; then
  echo -e "${RED}❌ Ollama ไม่ได้ทำงาน กรุณาเริ่มต้น Ollama ก่อน${NC}"
  echo -e "${YELLOW}ลองรัน: docker-compose up -d ollama${NC}"
  exit 1
fi

# ล้าง cache ของ Docker
echo -e "${BLUE}🧹 กำลังล้าง Docker cache...${NC}"
docker exec -it ollama-service rm -rf /root/.ollama/models/* 2>/dev/null || true

# สร้าง Modelfile
echo -e "${BLUE}📝 กำลังสร้าง Modelfile...${NC}"
./gen-modelfile.sh

# ดาวน์โหลดโมเดลจาก Ollama Library
echo -e "${BLUE}📥 กำลังดาวน์โหลดโมเดล ${MODEL_NAME} จาก Ollama Library...${NC}"
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
    
    # แสดงรายการโมเดลที่มีใน Ollama
    echo -e "${BLUE}📋 รายการโมเดลที่มีใน Ollama:${NC}"
    docker exec -it ollama-service ollama list
    
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🎉 การติดตั้งโมเดล ${MODEL_NAME} เสร็จสมบูรณ์!${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🤖 โมเดลที่ติดตั้ง: ${BLUE}${MODEL_ALIAS}${NC}"
    echo -e "${GREEN}🌐 คุณสามารถเข้าถึงโมเดลนี้ผ่าน OpenWebUI ได้ที่ ${BLUE}http://localhost:${WEBUI_PORT}${NC}"
    echo -e "${BLUE}======================================================${NC}"
  else
    echo -e "${RED}❌ ไม่สามารถสร้างโมเดลที่ปรับแต่งได้${NC}"
    echo -e "${YELLOW}⚠️ จะใช้โมเดลต้นฉบับแทน${NC}"
    echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs ollama-service${NC}"
  fi
else
  echo -e "${RED}❌ ไม่สามารถดาวน์โหลดโมเดล ${MODEL_NAME} ได้${NC}"
  echo -e "${YELLOW}ลองดูรายการโมเดลที่มีอยู่ใน Ollama Library:${NC}"
  docker exec -it ollama-service ollama list
  echo -e "${YELLOW}หรือตรวจสอบที่ https://ollama.com/library${NC}"
  exit 1
fi

exit 0