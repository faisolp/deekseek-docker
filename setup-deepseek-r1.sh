#!/bin/bash

# สคริปต์ติดตั้ง DeepSeek-R1-Distill-Qwen-14B สำหรับรองรับภาษาไทย
# วิธีใช้: ./setup-deepseek-r1.sh

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
echo -e "${GREEN}ติดตั้ง DeepSeek-R1-Distill-Qwen-14B บน MacBook Pro M4 + Colima${NC}"
echo -e "${BLUE}======================================================${NC}"

# ตรวจสอบว่า Colima และ Docker ทำงานอยู่หรือไม่
if ! docker ps &>/dev/null; then
  echo -e "${RED}❌ Docker ไม่สามารถเชื่อมต่อได้${NC}"
  echo -e "${YELLOW}🔄 กำลังรีสตาร์ท Colima...${NC}"
  
  colima stop &>/dev/null
  sleep 5
  colima start --cpu 6 --memory 15 --disk 100 --vm-type=vz --mount-type=virtiofs --arch aarch64
  
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

# สร้างโฟลเดอร์ Modelfile
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

# สร้าง docker-compose.yml สำหรับ DeepSeek-R1
echo -e "${BLUE}📝 กำลังสร้าง docker-compose.yml...${NC}"
cat > docker-compose.yml << EOL
# docker-compose.yml สำหรับใช้ DeepSeek-R1-Distill-Qwen-14B บน MacBook Pro M4 + Colima
services:
  # Ollama สำหรับรัน DeepSeek-R1
  ollama:
    image: ollama/ollama:latest
    platform: linux/arm64  # สำหรับ M4 chip
    container_name: ollama-service
    volumes:
      - ./ollama:/root/.ollama
    ports:
      - "11434:11434"
    extra_hosts:
      - "host.docker.internal:host-gateway"  # สำหรับ Colima
    environment:
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_ORIGINS=*
      - GPU_LAYERS=40    # เพิ่มจำนวน GPU layers สำหรับ deepseek-r1
      - METAL=1          # เปิดใช้งาน Metal (GPU)
    deploy:
      resources:
        limits:
          memory: 13G    # เพิ่ม RAM เป็น 13GB สำหรับโมเดลใหม่
          cpus: '6'      # ใช้ 6 cores
    networks:
      - llm-network
    restart: unless-stopped

  # OpenWebUI - Web Interface
  webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui
    volumes:
      - ./openwebui/data:/app/backend/data
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_API_BASE_URL=http://ollama-service:11434
      - WEBUI_AUTH=true
      - WEBUI_ENDPOINT_OLLAMA=true
      - WEBUI_ENDPOINT_LOCAL=false
      - WEBUI_USER=admin
      - WEBUI_PASS=adminpass
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1'
    depends_on:
      - ollama
    restart: unless-stopped
    networks:
      - llm-network

networks:
  llm-network:
    driver: bridge
EOL
echo -e "${GREEN}✅ สร้าง docker-compose.yml เรียบร้อย${NC}"

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

# ดาวน์โหลดและติดตั้งโมเดล DeepSeek-R1
echo -e "${BLUE}📥 กำลังดาวน์โหลดโมเดล $MODEL...${NC}"
echo -e "${YELLOW}⚠️ อาจใช้เวลา 10-20 นาที ขึ้นอยู่กับขนาดโมเดลและความเร็วอินเทอร์เน็ต${NC}"
docker exec -it ollama-service ollama pull $MODEL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ ดาวน์โหลดโมเดลเรียบร้อย${NC}"
  
  # สร้างโมเดลที่ปรับแต่งแล้วสำหรับภาษาไทย
  echo -e "${BLUE}🔧 กำลังสร้างโมเดลที่ปรับแต่งแล้ว ($MODEL_ALIAS)...${NC}"
  docker cp models/Modelfile.deepseek-r1 ollama-service:/tmp/Modelfile
  docker exec -it ollama-service ollama create $MODEL_ALIAS -f /tmp/Modelfile
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ สร้างโมเดลที่ปรับแต่งแล้ว ($MODEL_ALIAS) เรียบร้อย${NC}"
  else
    echo -e "${RED}❌ ไม่สามารถสร้างโมเดลที่ปรับแต่งได้${NC}"
    echo -e "${YELLOW}⚠️ จะใช้โมเดลต้นฉบับแทน${NC}"
    MODEL_ALIAS=$MODEL
  fi
else
  echo -e "${RED}❌ ไม่สามารถดาวน์โหลดโมเดล $MODEL ได้${NC}"
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
  echo -e "${GREEN}🌐 เข้าถึง OpenWebUI ได้ที่: ${BLUE}http://localhost:3000${NC}"
  echo -e "${GREEN}👤 ชื่อผู้ใช้: ${BLUE}admin${NC}"
  echo -e "${GREEN}🔑 รหัสผ่าน: ${BLUE}adminpass${NC}"
  echo -e "${GREEN}🤖 โมเดลที่ใช้: ${BLUE}$MODEL_ALIAS${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo -e "${YELLOW}📌 คำแนะนำการใช้งาน:${NC}"
  echo -e "  1. หลังจากล็อกอิน เลือกโมเดล '$MODEL_ALIAS' จากรายการ"
  echo -e "  2. สามารถทดสอบความสามารถในการใช้ภาษาไทยได้ทันที"
  echo -e "  3. ตั้งค่า temperature ระหว่าง 0.7-0.9 เพื่อความสมดุลระหว่างความแม่นยำและความคิดสร้างสรรค์"
  echo -e "${BLUE}======================================================${NC}"
else
  echo -e "${RED}❌ OpenWebUI ไม่ได้ทำงาน${NC}"
  echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs openwebui${NC}"
fi

exit 0