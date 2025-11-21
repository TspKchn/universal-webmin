# 🌐 Universal Webmin (Lightweight + Auto SSL)

สคริปต์นี้จะช่วยให้คุณ **ติดตั้ง Webmin อัตโนมัติ**, อัปเดตเป็นเวอร์ชันล่าสุดจาก SourceForge  
พร้อม **ตั้งค่า SSL (Let's Encrypt / Self-signed)** และ **ระบบ Auto Reload SSL** สำหรับ Webmin โดยอัตโนมัติ  
เหมาะสำหรับ VPS / GKE / Ubuntu Server ทั่วไป

---

## ⚡ คุณสมบัติเด่น

✅ ติดตั้ง Webmin อัตโนมัติ (ตรวจสอบเวอร์ชันล่าสุดจาก SourceForge)  
✅ รองรับ Ubuntu / Debian ทุกเวอร์ชัน  
✅ ตั้งค่า SSL อัตโนมัติจากไฟล์ที่มีอยู่ใน `/etc/ssl/universal-vpn/`  
✅ สร้างไฟล์ `.pem` สำหรับ Webmin  
✅ มีระบบ **Auto Reload SSL** เมื่อใบรับรองอัปเดต  
✅ ปลอดภัย น้ำหนักเบา ไม่ลงแพ็คเกจเกินจำเป็น  

---

## 🧩 โครงสร้างไฟล์ SSL ที่ต้องมี

ให้สร้างโฟลเดอร์ SSL ของคุณไว้ตามนี้ก่อน (หรือ Let’s Encrypt จะสร้างให้เอง)

```
/etc/ssl/universal-vpn/
├── fullchain.cer   # ใบรับรองหลัก (Certificate)
└── private.key     # Private Key
```

หากไม่มีใบรับรองจริง สคริปต์จะสร้าง Self-Signed Certificate ชั่วคราวให้แทน

---

## ⚙️ วิธีใช้งาน

### 🔹 ดาวน์โหลดสคริปต์ & รันติดตั้ง
```bash
wget -O universal-webmin.sh https://raw.githubusercontent.com/TspKchn/universal-webmin/main/universal-webmin.sh && chmod +x universal-webmin.sh && sudo bash universal-webmin.sh && rm -f universal-webmin.sh

```

สคริปต์จะ:
- อัปเดตระบบ
- ติดตั้ง Webmin (ล่าสุด)
- ตั้งค่า SSL
- เปิดพอร์ต 10000
- สร้าง Auto Reload SSL service

---

## 🔐 วิธีเข้าหน้า Webmin

หลังติดตั้งเสร็จ เข้าผ่าน URL:
```
https://<your-server-ip>:10000/
```

หากคุณใช้โดเมน (เช่น `test.xq-vpn.com`) และมีใบรับรองใน `/etc/ssl/universal-vpn/`  
ระบบจะโหลด SSL จริงอัตโนมัติ และไม่ขึ้น “หน้าเว็บสีแดง” อีกต่อไป ✅

---

## 🔄 Auto SSL Reload

ระบบจะตรวจจับการอัปเดตไฟล์:
```
/etc/ssl/universal-vpn/fullchain.cer
/etc/ssl/universal-vpn/private.key
```
แล้วทำการรีโหลด Webmin อัตโนมัติผ่าน systemd service:
```
webmin-auto-ssl.path
webmin-auto-ssl.service
```

ตรวจสอบสถานะได้ด้วย:
```bash
systemctl status webmin-auto-ssl.path
```

---

## 📁 ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | รายละเอียด |
|------|-------------|
| `/usr/local/bin/webmin-auto-ssl.sh` | สคริปต์ตรวจจับ SSL และรีโหลด Webmin |
| `/etc/systemd/system/webmin-auto-ssl.path` | ตรวจจับการเปลี่ยนแปลงใบรับรอง |
| `/etc/systemd/system/webmin-auto-ssl.service` | ทำงานเมื่อ SSL เปลี่ยนแปลง |
| `/etc/ssl/webmin/miniserv.pem` | ไฟล์ใบรับรองรวมที่ Webmin ใช้จริง |

---

## 🧰 ตรวจสอบ Webmin

```bash
systemctl status webmin
```

ถ้า Active แล้วสามารถเข้าเว็บได้ทันที  
> 🔸 ถ้ายังขึ้นหน้าแดง แสดงว่าใช้ Self-Signed Cert (ยังไม่มี SSL จริง)

---

## 🧹 ถอนการติดตั้ง (ถ้าต้องการ)

```bash
apt remove webmin -y
rm -rf /etc/webmin /usr/share/webmin /etc/ssl/webmin
systemctl disable webmin webmin-auto-ssl.path webmin-auto-ssl.service
```

---

## ✨ ข้อมูลเพิ่มเติม

- โฟลเดอร์ SSL ตั้งอยู่ที่: `/etc/ssl/universal-vpn/`
- ถ้าคุณใช้ Certbot ให้ตั้งค่า renew hook เพื่อรีโหลด Webmin อัตโนมัติได้เช่นกัน
- สคริปต์นี้ทดสอบแล้วบน Ubuntu 18.04 / 20.04 / 22.04 / 24.04

---

## 🧾 License
MIT License  
Created by **ChatGPT (for XQ-VPN Project)**  
© 2025 — Use freely for educational & production purposes.
