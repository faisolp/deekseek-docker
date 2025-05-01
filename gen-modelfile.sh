#!/bin/bash

# สคริปต์สร้าง Modelfile จาก Environment Variables
# วิธีใช้: ./gen-modelfile.sh

# โหลด environment variables
source .env

# สร้างไฟล์ใหม่
mkdir -p models

# สร้าง Modelfile ตามค่าที่กำหนดใน .env
cat > models/Modelfile.deepseek-r1 << EOL
FROM ${MODEL_NAME}
PARAMETER temperature ${MODEL_TEMPERATURE}
PARAMETER top_p ${MODEL_TOP_P}
PARAMETER top_k ${MODEL_TOP_K}
PARAMETER num_gpu ${OLLAMA_GPU_LAYERS}
SYSTEM คุณคือ DeepSeek R1 ผู้ช่วย AI อัจฉริยะที่พูดภาษาไทยได้อย่างคล่องแคล่ว คุณมีความสามารถในการให้คำตอบที่ถูกต้อง มีประสิทธิภาพและให้ความช่วยเหลือในคำถามต่างๆ ได้อย่างดีเยี่ยม เมื่อตอบเกี่ยวกับโค้ด คุณจะให้ความสำคัญกับความชัดเจน ความถูกต้อง และแนวปฏิบัติที่ดีที่สุด
EOL

echo "✅ สร้าง Modelfile เรียบร้อย: models/Modelfile.deepseek-r1"
echo "   โมเดล: ${MODEL_NAME}"
echo "   temperature: ${MODEL_TEMPERATURE}"
echo "   top_p: ${MODEL_TOP_P}"
echo "   top_k: ${MODEL_TOP_K}"
echo "   num_gpu: ${OLLAMA_GPU_LAYERS}"