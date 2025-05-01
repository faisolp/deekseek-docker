#!/bin/bash

# สคริปต์สำหรับติดตั้งโมเดล DeepSeek-R1 14B โดยเฉพาะ
# วิธีใช้: ./pull-deepseek-r1.sh

# สีสำหรับข้อความ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# โมเดลที่ต้องการติดตั้ง
MODEL="deepseek-r1:14b"
MODEL_ALIAS="deepseek-r1-thai"

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}ติดตั้งโมเดล DeepSeek-R1 14B จาก Ollama Library${NC}"
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

# สร้างโฟลเดอร์ Modelfile ถ้ายังไม่มี
mkdir -p models

# สร้าง Modelfile สำหรับ DeepSeek-R1 ที่รองรับภาษาไทย
echo -e "${BLUE}📝 กำลังสร้าง Modelfile สำหรับ DeepSeek-R1...${NC}"
cat > models/Modelfile.deepseek-r1 << EOL
FROM deepseek-r1:14b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_gpu 40
SYSTEM คุณคือ DeepSeek R1 ผู้ช่วย AI อัจฉริยะที่พูดภาษาไทยได้อย่างคล่องแคล่ว คุณมีความสามารถในการให้คำตอบที่ถูกต้อง มีประสิทธิภาพและให้ความช่วยเหลือในคำถามต่างๆ ได้อย่างดีเยี่ยม เมื่อตอบเกี่ยวกับโค้ด คุณจะให้ความสำคัญกับความชัดเจน ความถูกต้อง และแนวปฏิบัติที่ดีที่สุด
EOL
echo -e "${GREEN}✅ สร้าง Modelfile เรียบร้อย${NC}"

# ดาวน์โหลดโมเดล DeepSeek-R1 จาก Ollama Library
echo -e "${BLUE}📥 กำลังดาวน์โหลดโมเดล $MODEL จาก Ollama Library...${NC}"
echo -e "${YELLOW}⚠️ อาจใช้เวลา 10-20 นาที ขึ้นอยู่กับความเร็วอินเทอร์เน็ต${NC}"
docker exec -it ollama-service ollama pull $MODEL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ ดาวน์โหลดโมเดลเรียบร้อย${NC}"
  
  # สร้างโมเดลที่ปรับแต่งแล้วสำหรับภาษาไทย
  echo -e "${BLUE}🔧 กำลังสร้างโมเดลที่ปรับแต่งแล้ว ($MODEL_ALIAS)...${NC}"
  docker cp models/Modelfile.deepseek-r1 ollama-service:/tmp/Modelfile
  docker exec -it ollama-service ollama create $MODEL_ALIAS -f /tmp/Modelfile
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ สร้างโมเดลที่ปรับแต่งแล้ว ($MODEL_ALIAS) เรียบร้อย${NC}"
    
    # แสดงรายการโมเดลที่มีใน Ollama
    echo -e "${BLUE}📋 รายการโมเดลที่มีใน Ollama:${NC}"
    docker exec -it ollama-service ollama list
    
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🎉 การติดตั้งโมเดล DeepSeek-R1 เสร็จสมบูรณ์!${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${GREEN}🤖 โมเดลที่ติดตั้ง: ${BLUE}$MODEL_ALIAS${NC}"
    echo -e "${GREEN}🌐 คุณสามารถเข้าถึงโมเดลนี้ผ่าน OpenWebUI ได้ที่ ${BLUE}http://localhost:3000${NC}"
    echo -e "${BLUE}======================================================${NC}"
  else
    echo -e "${RED}❌ ไม่สามารถสร้างโมเดลที่ปรับแต่งได้${NC}"
    echo -e "${YELLOW}⚠️ จะใช้โมเดลต้นฉบับแทน${NC}"
    echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs ollama-service${NC}"
  fi
else
  echo -e "${RED}❌ ไม่สามารถดาวน์โหลดโมเดล $MODEL ได้${NC}"
  echo -e "${YELLOW}ลองดูรายการโมเดลที่มีอยู่ใน Ollama Library:${NC}"
  docker exec -it ollama-service ollama list
  echo -e "${YELLOW}หรือตรวจสอบที่ https://ollama.com/library${NC}"
  exit 1
fi

exit 00