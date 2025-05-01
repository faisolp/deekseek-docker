# DeepSeek-R1-Thai 🤖 - ภาษาไทย

ระบบ AI ภาษาไทยด้วย DeepSeek-R1 14B บน MacBook M-series ใช้ Docker + Colima

![DeepSeek-R1 Logo](https://img.shields.io/badge/DeepSeek--R1-Thai-brightgreen?style=for-the-badge)

## 📋 คุณสมบัติ

- 🇹🇭 **รองรับภาษาไทย**: โมเดลได้รับการปรับแต่งให้ตอบคำถามภาษาไทยได้อย่างดีเยี่ยม
- 💡 **แรงด้านโค้ด**: พื้นฐานมาจาก DeepSeek-Coder จึงมีความสามารถด้านโค้ดสูง
- 🍎 **ทำงานบน M-series**: ใช้ GPU ของชิป Apple Silicon เพื่อประสิทธิภาพสูงสุด
- 🐳 **Docker + Colima**: ใช้งานได้ทั้งใน Docker Desktop และ Colima
- 🌐 **Web UI**: มาพร้อม Open WebUI ที่ใช้งานง่าย มีฟีเจอร์ครบครัน

## 🖥️ ความต้องการระบบ

- macOS บน Apple Silicon (M1, M2, M3, M4)
- Docker หรือ Colima
- พื้นที่ว่างอย่างน้อย 15GB
- RAM อย่างน้อย 16GB (แนะนำ 32GB)

## ⚙️ การติดตั้ง

### 👉 วิธีที่ 1: ติดตั้งทั้งระบบแบบครบวงจร

สคริปต์ `setup-deepseek-r1.sh` ติดตั้งระบบ DeepSeek-R1-Thai ทั้งหมดแบบครบวงจร:
- ✅ ตรวจสอบและรีสตาร์ท Colima (ถ้าจำเป็น)
- ✅ ตั้งค่า docker-compose.yml
- ✅ สร้าง Modelfile ที่รองรับภาษาไทย
- ✅ ติดตั้ง Ollama และ OpenWebUI 
- ✅ ดาวน์โหลดโมเดล DeepSeek-R1 14B
- ✅ ปรับแต่งโมเดลให้รองรับภาษาไทย

1. **เตรียม Repository และสคริปต์**

```bash
# ให้สิทธิ์การรันสคริปต์
chmod +x setup-deepseek-r1.sh colima-restart-r1.sh pull-deepseek-r1.sh
```

2. **เริ่มต้น Colima** (ข้ามขั้นตอนนี้ถ้าใช้ Docker Desktop)

```bash
./colima-restart-r1.sh
```

3. **ติดตั้งระบบทั้งหมด**

```bash
./setup-deepseek-r1.sh
```

### 👉 วิธีที่ 2: ติดตั้งเฉพาะโมเดล (ถ้าระบบ Ollama ทำงานอยู่แล้ว)

สคริปต์ `pull-deepseek-r1.sh` เน้นเฉพาะการติดตั้งโมเดล:
- ✅ ดาวน์โหลดโมเดล DeepSeek-R1 14B
- ✅ สร้าง Modelfile ที่รองรับภาษาไทย
- ✅ ปรับแต่งโมเดลให้ตอบภาษาไทยได้ดี

ใช้เมื่อ:
- Ollama และ WebUI ทำงานอยู่แล้ว
- ต้องการติดตั้งเฉพาะโมเดล DeepSeek-R1
- มีปัญหาในการดาวน์โหลดโมเดลจากสคริปต์หลัก

```bash
# ตรวจสอบว่า Ollama ทำงานอยู่
docker ps | grep ollama-service

# ถ้า Ollama ยังไม่ทำงาน ให้รัน
docker-compose up -d ollama

# ติดตั้งโมเดล
./pull-deepseek-r1.sh
```

> ⚠️ **หมายเหตุ**: การดาวน์โหลดโมเดลใช้เวลาประมาณ 10-20 นาที ขึ้นอยู่กับความเร็วอินเทอร์เน็ต

### เข้าใช้งาน Web UI

- เปิดเบราว์เซอร์ไปที่ http://localhost:3000
- ล็อกอินด้วย:
  - ชื่อผู้ใช้: `admin`
  - รหัสผ่าน: `adminpass`

- **เลือกโมเดล DeepSeek-R1-Thai** หลังจากล็อกอิน

## 🚀 คำสั่งที่มีประโยชน์

### รีสตาร์ท Colima

```bash
./colima-restart-r1.sh
```

### หยุดการทำงานทั้งหมด

```bash
docker-compose down
colima stop  # ถ้าใช้ Colima
```

### เริ่มระบบใหม่หลังจากรีบูต

```bash
# เริ่ม Colima (ถ้าใช้)
colima start --cpu 6 --memory 15 --disk 100 --vm-type=vz --mount-type=virtiofs --arch aarch64

# เริ่ม Docker Compose
docker-compose up -d
```

### ล้าง Docker ทั้งหมด (ระวัง!)

```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q) -f
docker system prune -a --volumes
```

## 📊 การปรับแต่งประสิทธิภาพ

### ปรับแต่ง Modelfile

แก้ไขไฟล์ `models/Modelfile.deepseek-r1` เพื่อเปลี่ยนค่า Parameters:

```
PARAMETER temperature 0.7  # ค่าระหว่าง 0.1-1.0 (ต่ำ = แม่นยำ, สูง = สร้างสรรค์)
PARAMETER top_p 0.9        # ค่าระหว่าง 0.1-1.0
PARAMETER top_k 40         # จำนวนโทเค็นที่พิจารณา
```

### ปรับแต่ง Docker Resources

แก้ไขไฟล์ `docker-compose.yml` เพื่อเปลี่ยนการกำหนดทรัพยากร:

```yaml
deploy:
  resources:
    limits:
      memory: 13G    # ปรับตามปริมาณ RAM ที่มี
      cpus: '6'      # ปรับตามจำนวน CPU ที่ต้องการใช้
```

## 🔍 การแก้ไขปัญหา

### ตรวจสอบสถานะ

```bash
# ดูสถานะ containers
docker ps

# ดูบันทึกของ Ollama
docker logs ollama-service

# ดูบันทึกของ OpenWebUI
docker logs openwebui
```

### ปัญหาทั่วไป

1. **Colima ไม่สามารถเริ่มต้นได้**:
   - ตรวจสอบความต้องการระบบ
   - ลดการใช้ CPU และ RAM ลงในไฟล์ `colima-restart-r1.sh`

2. **ไม่สามารถดาวน์โหลดโมเดลได้**:
   - ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
   - รันเฉพาะสคริปต์ `pull-deepseek-r1.sh` เพื่อดาวน์โหลดเฉพาะโมเดล
   - ตรวจสอบว่าชื่อโมเดลถูกต้อง (ควรเป็น `deepseek-r1:14b`)
   - ลองเพิ่ม `--insecure` หรือเปลี่ยน DNS หากมีปัญหาการเชื่อมต่อ

3. **OpenWebUI ไม่ทำงาน**:
   - ตรวจสอบบันทึกด้วย `docker logs openwebui`
   - ตรวจสอบว่า ports 3000 ไม่ถูกใช้งานโดยแอปอื่น

4. **โมเดลทำงานแล้วแต่ไม่พูดภาษาไทย**:
   - ตรวจสอบว่ากำลังใช้โมเดล `deepseek-r1-thai` (ไม่ใช่ `deepseek-r1:14b`)
   - รีสตาร์ทด้วย `docker-compose restart`

## 📈 แนวทางการใช้งาน

### คำแนะนำในการใช้งาน

1. **เขียนโค้ด**:
   - ใช้ temperature ต่ำ (0.1-0.3) เพื่อความแม่นยำ
   - ระบุภาษาที่ต้องการให้ชัดเจน

2. **การสนทนาทั่วไป**:
   - ใช้ temperature ปานกลาง (0.7) สำหรับการสนทนาที่เป็นธรรมชาติ
   - พิมพ์ภาษาไทยได้เลย โมเดลเข้าใจภาษาไทยดี

3. **การสร้างสรรค์**:
   - ใช้ temperature สูง (0.8-1.0) สำหรับงานสร้างสรรค์
   - ใช้ top_p สูง (0.9-0.95) เพื่อความหลากหลาย

## 📝 อ้างอิง

- [DeepSeek R1 Official](https://github.com/deepseek-ai/deepseek-coder)
- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [Docker](https://www.docker.com/)
- [Colima](https://github.com/abiosoft/colima)

## 📜 License

[MIT License](LICENSE)

---

พัฒนาโดย [Your Name] | แก้ไขล่าสุด: พฤษภาคม 2565