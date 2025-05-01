#!/bin/bash

# สคริปต์ติดตั้ง Deepseek ด้วยชื่อโมเดลที่ถูกต้อง
# วิธีใช้: ./setup-deepseek-correct.sh

# สีสำหรับข้อความ
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# โมเดลที่มีใน Ollama
MODEL="deepseek-coder"
MODEL_ALIAS="deepseek-optimized"

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}ติดตั้ง Deepseek บน MacBook Pro M4 + Colima${NC}"
echo -e "${BLUE}======================================================${NC}"

# ตรวจสอบว่า Colima และ Docker ทำงานอยู่หรือไม่

# สร้างโฟลเดอร์ Modelfile
mkdir -p models

# สร้าง Modelfile สำหรับ Deepseek Optimized
echo -e "${BLUE}📝 กำลังสร้าง Modelfile สำหรับ Deepseek...${NC}"
cat > models/Modelfile.deepseek << EOL
FROM deepseek-coder
PARAMETER temperature 0.6
PARAMETER top_p 0.8
PARAMETER top_k 40
PARAMETER num_gpu 40
SYSTEM You are DeepSeek Coder, a state-of-the-art AI coding assistant. You provide accurate, efficient, and helpful responses to technical questions. For code, you prioritize clarity, correctness, and best practices.
EOL
echo -e "${GREEN}✅ สร้าง Modelfile เรียบร้อย${NC}"

# หยุดการทำงานของ containers ที่มีอยู่
echo -e "${BLUE}🛑 กำลังหยุด containers ที่ทำงานอยู่...${NC}"
docker stop $(docker ps -q) 2>/dev/null || true
docker-compose down 2>/dev/null || true

# ล้าง containers และ networks ที่เกี่ยวข้อง
echo -e "${BLUE}🧹 กำลังล้าง containers และ networks ที่ไม่ได้ใช้...${NC}"
docker network prune -f &>/dev/null
docker system prune -f &>/dev/null


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

# รายการโมเดลแนะนำที่มีอยู่จริงใน Ollama
echo -e "${BLUE}📋 รายการโมเดลที่แนะนำ:${NC}"
echo -e "${GREEN}1. deepseek-coder${NC} - โมเดลโปรแกรมมิ่งที่ทรงพลัง"
echo -e "${GREEN}2. llama3${NC} - โมเดล Meta AI ล่าสุด"
echo -e "${GREEN}3. phi3${NC} - โมเดล Microsoft ขนาดเล็กแต่ทรงประสิทธิภาพ"
echo -e "${GREEN}4. mistral${NC} - โมเดลทางเลือกที่มีประสิทธิภาพดี"
echo -e "${GREEN}5. gemma${NC} - โมเดลจาก Google ทรงประสิทธิภาพ"

# ให้ผู้ใช้เลือกโมเดล
echo -e "${YELLOW}โปรดเลือกโมเดลที่ต้องการ (1-5) หรือกด Enter เพื่อใช้ deepseek-coder: ${NC}"
read choice

case "$choice" in
  "1"|"")
    MODEL="deepseek-coder"
    ;;
  "2")
    MODEL="llama3"
    ;;
  "3")
    MODEL="phi3"
    ;;
  "4")
    MODEL="mistral"
    ;;
  "5")
    MODEL="gemma"
    ;;
  *)
    echo -e "${RED}ตัวเลือกไม่ถูกต้อง ใช้ deepseek-coder แทน${NC}"
    MODEL="deepseek-coder"
    ;;
esac

MODEL_ALIAS="${MODEL}-optimized"

# ตรวจสอบว่า Ollama container ทำงานหรือไม่
if docker ps | grep -q "ollama-service"; then
  echo -e "${GREEN}✅ Ollama ทำงานแล้ว${NC}"
  
  # ตรวจสอบ Ollama API
  if curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo -e "${GREEN}✅ สามารถเชื่อมต่อกับ Ollama API ได้${NC}"
    
    # ดาวน์โหลดโมเดล
    echo -e "${BLUE}📥 กำลังดาวน์โหลดโมเดล $MODEL...${NC}"
    echo -e "${YELLOW}⚠️ อาจใช้เวลา 5-15 นาที ขึ้นอยู่กับขนาดโมเดลและความเร็วอินเทอร์เน็ต${NC}"
    docker exec -it ollama-service ollama pull $MODEL
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ ดาวน์โหลดโมเดลเรียบร้อย${NC}"
      
      # แก้ไข Modelfile ให้ตรงกับโมเดลที่เลือก
      sed -i "" "s/FROM deepseek-coder/FROM $MODEL/" models/Modelfile.deepseek
      
      # สร้างโมเดลที่ปรับแต่งแล้ว
      echo -e "${BLUE}🔧 กำลังสร้างโมเดลที่ปรับแต่งแล้ว ($MODEL_ALIAS)...${NC}"
      docker cp models/Modelfile.deepseek ollama-service:/tmp/Modelfile
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
      echo -e "  1. หลังจากล็อกอิน เลือกโมเดล '${MODEL_ALIAS}' จากรายการ"
      echo -e "  2. ตั้งค่า temperature ต่ำ (0.2-0.5) เพื่อคำตอบที่แม่นยำยิ่งขึ้น"
      echo -e "  3. สามารถใช้ไฟล์เป็นพารามิเตอร์กับสคริปต์นี้เพื่อเริ่มต้นใหม่ได้ทุกเมื่อ"
      echo -e "${BLUE}======================================================${NC}"
    else
      echo -e "${RED}❌ OpenWebUI ไม่ได้ทำงาน${NC}"
      echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs openwebui${NC}"
    fi
  else
    echo -e "${RED}❌ ไม่สามารถเชื่อมต่อกับ Ollama API ได้${NC}"
    echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs ollama-service${NC}"
  fi
else
  echo -e "${RED}❌ Ollama ไม่ได้ทำงาน${NC}"
  echo -e "${YELLOW}ตรวจสอบบันทึก: ${BLUE}docker logs ollama-service${NC}"
fi

exit 0