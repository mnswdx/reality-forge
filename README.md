# ⚡ Reality Forge

> **Автоматический One-Click инсталлятор эталонного узла VLESS-REALITY + 3x-ui для Linux VPS.**  
> Развернул, отсканировал QR-код и пользуешься. Без ручных настроек, с максимальной маскировкой от ТСПУ/РКН и защитой панели через SSH-туннель.

[![License: Unlicense](https://img.shields.io/badge/License-Unlicense-blue.svg)](LICENSE)
[![Protocol](https://img.shields.io/badge/Protocol-VLESS--REALITY-success.svg)](https://github.com/XTLS/Xray-core)
[![Flow](https://img.shields.io/badge/Flow-xtls--rprx--vision-orange.svg)](https://github.com/XTLS/Xray-core)
[![Platform](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-lightgrey.svg)](https://ubuntu.com)

---

## 🚀 Быстрый старт (Развертывание в 1 команду)

Подключитесь к вашему чистому VPS по SSH (`root@<IP_СЕРВЕРА>`) и выполните одну команду:

```bash
curl -sSL https://raw.githubusercontent.com/mnswdx/reality-forge/main/install.sh | bash
```

> [!NOTE]
> Скрипт совместим с **Ubuntu 20.04 / 22.04 / 24.04** и **Debian 11 / 12**. Время развертывания — около 1–2 минут.

---

## ⚠️ Золотое правило REALITY: почему нельзя брать Microsoft, Sony, Apple и Google?

Многие статьи и любительские видео в интернете советуют указывать в качестве маскировочного донора популярные сайты: `microsoft.com`, `sony.com`, `apple.com`, `google.com`, `yahoo.com`.

**ЭТО ФАТАЛЬНАЯ ОШИБКА, которая приводит к гарантированной блокировке вашего туннеля!**

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  ❌ ПОЧЕМУ ПОПУЛЯРНЫЕ САЙТЫ УБИВАЮТ ВАШ ТУННЕЛЬ?                                       │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  1. IP-SNI Mismatch (Детекция со стороны ТСПУ / РКН):                                  │
│     ТСПУ хранит точные диапазоны IP-адресов корпораций уровня Microsoft и Google.     │
│     Когда клиент отправляет пакет на IP вашего VPS (например, на неизвестном европейском│
│     хостинге), но в поле SNI указывает "microsoft.com", ТСПУ мгновенно видит аномалию:  │
│     "IP-адрес назначения НЕ принадлежит Microsoft". Соединение разрывается (TCP RST).  │
│                                                                                        │
│  2. Ловушка CDN (Cloudflare, Akamai, Fastly):                                          │
│     Крупные мировые порталы висят за CDN. Поддомены и IP этих CDN часто находятся под   │
│     ковровыми блокировками или не отдают протокол HTTP/2 (h2) при проверке проброса     │
│     (Fallbacks), из-за чего рукопожатие Xray завершается ошибкой.                      │
│                                                                                        │
│  3. Сетевая неестественность:                                                          │
│     Если ваш сервер находится в Хельсинки, а SNI указывает на американский сервер Sony │
│     в Калифорнии — задержка рукопожатия и маршрут TLS вызывают подозрение DPI.         │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### ✅ Как делает Reality Forge:
Скрипт автоматически определяет страну вашего VPS (Нидерланды 🇳🇱, Финляндия 🇫🇮, Литва 🇱🇹, Германия 🇩🇪, Франция 🇫🇷 и др.) и подбирает **проверенного регионального донора**:
- Из национальной академической или телеком-инфраструктуры (университеты, государственные IT-центры, точки обмена IXP).
- **Без Cloudflare / CDN** (прямой сервер).
- Со строгим **TLS 1.3** и поддержкой **HTTP/2 (h2)**.

---

## 🛠️ Что Reality Forge делает «из коробки»

1. **Анализ геолокации и выбор донора:**
   - Определяет внешний IP, город и страну сервера через независимые API.
   - Предлагает оптимального донора для вашей зоны либо позволяет ввести свой проверенный домен.
2. **Твикинг сетевого стека Linux (BBR):**
   - Включает алгоритм контроля перегрузки **TCP BBR** и дисциплину очередей `fq` для максимальной скорости (YouTube 4K без задержек и подвисаний).
   - Оптимизирует лимиты сокетов `somaxconn` и буферы TCP.
3. **Установка 3x-ui:**
   - Разворачивает актуальную версию веб-панели управления `3x-ui` (MHSanaei).
4. **Эталонная безопасность веб-панели (SSH-туннель):**
   - Панель привязывается **исключительно к `127.0.0.1`** (локалхост).
   - Порт панели **НЕ светит в открытый интернет** — боты Shodan, Censys и сканеры РКН не увидят веб-интерфейс панели.
   - Генерируется случайный секретный URL-путь (например, `/forge-a1b2/`) и надежный пароль администратора.
5. **Файрвол (UFW) и защита от брутфорса (Fail2ban):**
   - Блокирует все входящие порты, кроме SSH (22) и VLESS-REALITY (443 TCP/UDP).
   - Защищает SSH от подбора паролей через Fail2ban.
6. **Автоматическое создание Inbound VLESS-REALITY:**
   - Протокол: `VLESS`.
   - Порт: `443` (стандартный HTTPS трафик).
   - Flow: `xtls-rprx-vision` (обязателен для маскировки под легитимный браузерный трафик).
   - Генерация ключей x25519 (`privateKey`, `publicKey`) и 8-значного `Short ID`.
7. **Клиентская ссылка и QR-код:**
   - Выводит готовую ссылку `vless://...`.
   - Отрисовывает терминальный QR-код прямо на экране для мгновенного добавления в смартфон.
   - Сохраняет все учетные данные в файл на сервере: `/root/reality-forge-credentials.txt` (доступ `chmod 600`).

---

## 🖥️ Как зайти в веб-панель 3x-ui (Безопасный SSH-туннель)

Поскольку панель не выставлена в открытый интернет, доступ к ней осуществляется через защищённый SSH-туннель:

1. На вашем компьютере (в Windows PowerShell, терминале macOS или Linux) выполните команду:
   ```bash
   ssh -N -L 5541:127.0.0.1:5541 root@<IP_ВАШЕГО_СЕРВЕРА>
   ```
2. Откройте браузер и перейдите по адресу:
   ```
   http://127.0.0.1:5541/forge-xxxx/
   ```
   *(точные данные порта, пути, логина и пароля скрипт выведет в конце установки и сохранит в `/root/reality-forge-credentials.txt`)*.

---

## 📱 Клиенты для подключения

| Платформа | Рекомендуемый клиент | Как добавить |
| :--- | :--- | :--- |
| **iOS / iPadOS** | **Happ** или **V2Box** | Отсканировать QR-код камерой в приложении |
| **Android** | **Happ**, **v2rayNG** или **NekoBox** | Отсканировать QR-код или вставить `vless://` из буфера |
| **Windows** | **v2rayN** или **NekoBox for Windows** | Скопировать ссылку `vless://` и нажать `Ctrl+V` |
| **macOS** | **V2Box** или **FoXray** | Добавить через буфер обмена или QR-код |

---

## ⚡ Раздельный туннель: SplitStream Turbo (Happ)

Чтобы российские сервисы (Сбер, Т-Банк, Госуслуги, Ozon, WB, Кинопоиск, Яндекс) открывались напрямую на максимальной скорости домашнего провайдера, а заблокированные ресурсы и YouTube шли через REALITY, импортируйте профиль маршрутизации в клиент Happ:

```
happ://routing/add/eyJHZW9zaXRlVXJsIjoiaHR0cHM6XC9cL2docHJveHkubmV0XC9odHRwczpcL1wvZ2l0aHViLmNvbVwva2VwbGVyMTAzYlwvZ2VvLWZvci1ydS1vbmx5XC9yZWxlYXNlc1wvZG93bmxvYWRcL2xhdGVzdFwvZ2Vvc2l0ZS5kYXQiLCJEaXJlY3RJcCI6WyIxMC4wLjAuMFwvOCIsIjEwMC42NC4wLjBcLzEwIiwiMTcyLjE2LjAuMFwvMTIiLCIxOTIuMTY4LjAuMFwvMTYiLCIxNjkuMjU0LjAuMFwvMTYiLCIyMjQuMC4wLjBcLzQiLCIyNTUuMjU1LjI1NS4yNTUiLCJnZW9pcDpnZW9pcC1ydS1kb21lc3RpYyIsImdlb2lwOnByaXZhdGUiXSwiRG9tZXN0aWNETlNJcCI6IjEuMC4wLjEiLCJGYWtlRG5zIjp0cnVlLCJSb3V0ZU9yZGVyIjoiYmxvY2stZGlyZWN0LXByb3h5IiwiRG9tYWluU3RyYXRlZ3kiOiJJUElmTm9uTWF0Y2giLCJMYXN0VXBkYXRlZCI6MTc3NTIxNjMzMiwiQmxvY2tTaXRlcyI6W10sIlVzZUNodW5rRmlsZXMiOnRydWUsIlByb3h5SXAiOltdLCJHZW9pcFVybCI6Imh0dHBzOlwvXC9naHByb3h5Lm5ldFwvaHR0cHM6XC9cL2dpdGh1Yi5jb21cL2tlcGxlcjEwM2JcL2dlby1mb3ItcnUtb25seVwvcmVsZWFzZXNcL2Rvd25sb2FkXC9sYXRlc3RcL2dlb2lwLmRhdCIsIlJlbW90ZUROU0lwIjoiMS4xLjEuMSIsIkdsb2JhbFByb3h5Ijp0cnVlLCJCbG9ja0lwIjpbXSwiTmFtZSI6IlNwbGl0U3RyZWFtIFR1cmJvIFJVIiwiUmVtb3RlRE5TVHlwZSI6IkRvVSIsIlJlbW90ZUROU0RvbWFpbiI6Imh0dHBzOlwvXC9jbG91ZGZsYXJlLWRucy5jb21cL2Rucy1xdWVyeSIsIlByb3h5U2l0ZXMiOltdLCJEbnNIb3N0cyI6eyJjbG91ZGZsYXJlLWRucy5jb20iOiIxLjEuMS4xIiwiZG5zLmdvb2dsZSI6IjguOC44LjgifSwiRG9tZXN0aWNETlNUeXBlIjoiRG9VIiwiRGlyZWN0U2l0ZXMiOlsiZ2Vvc2l0ZTp2ayIsImdlb3NpdGU6a2lub3BvaXNrIiwiZ2Vvc2l0ZTphdmlhc2FsZXMiLCJnZW9zaXRlOmRyd2ViIiwiZ2Vvc2l0ZTp3aWxkYmVycmllcyIsImdlb3NpdGU6cnV0dWJlIiwiZ2Vvc2l0ZTpvem9uIiwiZ2Vvc2l0ZTp3aW5rIiwiZ2Vvc2l0ZToyZ2lzIiwiZ2Vvc2l0ZTprYXNwZXJza3kiLCJnZW9zaXRlOm9rIiwiZ2Vvc2l0ZTp5YW5kZXgiLCJnZW9zaXRlOm9ra28iLCJnZW9zaXRlOmF2aXRvIiwiZ2Vvc2l0ZTptb3NtZXRybyIsImdlb3NpdGU6ZHplbiIsImdlb3NpdGU6bWFpbHJ1IiwiZ2Vvc2l0ZTptYWlscnUtZ3JvdXAiLCJnZW9zaXRlOmNhdGVnb3J5LXRyYXZlbC1ydSIsImdlb3NpdGU6eDUiLCJnZW9zaXRlOmNhdGVnb3J5LWdvdi1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktZW50ZXJ0YWlubWVudC1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktcmV0YWlsLXJ1IiwiZ2Vvc2l0ZTpjYXRlZ29yeS1tZWRpY2luZS1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktbWVkaWEtcnUiLCJnZW9zaXRlOmNhdGVnb3J5LWVjb21tZXJjZS1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktcnUiLCJnZW9zaXRlOmNhdGVnb3J5LWJhbmstcnUiXSwiRG9tZXN0aWNETlNEb21haW4iOiJodHRwczpcL1wvZG5zLmdvb2dsZVwvZG5zLXF1ZXJ5In0=
```

---

## 🧩 Единая экосистема инструментов

Reality Forge идеально дополняется другими компонентами этой экосистемы:

1. **[Reality Radar & Sentinel CLI](https://github.com/mnswdx/reality-radar-cli):**  
   Инструмент на ПК для сканирования и скоринга альтернативных доноров REALITY, контроля здоровья VPS, проверки пинга/джиттера и управления SSH-туннелем к панели.
2. **[Project Phoenix](https://github.com/mnswdx/phoenix-vps):**  
   Система автономного шифрованного бэкапа и аварийного восстановления конфигурации вашего сервера (Disaster Recovery).
3. **[SplitStream](https://github.com/mnswdx/splitstream):**  
   Компилятор и кастомизатор списков маршрутизации для любых клиентов.

---

## 📄 Лицензия

Распространяется свободно в общественном достоянии под лицензией [The Unlicense](LICENSE). Никаких ограничений, свободно для личного и коммерческого использования.
