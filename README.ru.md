# Debian на Acer Iconia Tab 8 (W1-810)

Пошаговая установка Debian 12 (Xfce) на Acer Iconia Tab 8 W1-810 и настройки, после которых планшетом удобно пользоваться без клавиатуры.

[English version](README.md)

## Что работает

| Компонент | Статус | Как |
|---|---|---|
| Загрузка с eMMC | ✅ | 32-битный GRUB и ручная правка `BootOrder` ([шаг 5](#5-починка-no-bootable-device)) |
| Wi-Fi (BCM4330 SDIO) | ✅ | NVRAM от Prowise-PT301 под именем модели |
| Bluetooth (BCM4330B1 UART) | ✅ | Патч `BCM4330B1.hcd` из LibreELEC |
| Звук (RT5640, динамики) | ✅ | `firmware-intel-sound` (квирк для W1-810 уже есть в ядре) |
| Тачскрин (Goodix) | ✅ | Работает сразу, калибровка по желанию |
| Автоповорот (BMA222E) | ✅ | `iio-sensor-proxy` и `scripts/autorotate` |
| Правая кнопка | ✅ | Долгий тап, `scripts/longpress-rightclick` |
| Экранная клавиатура | ✅ | `onboard` с автопоказом, есть и на экране входа |
| Камеры | ❌ | Не проверялись, драйвера нет |

## Особенности железа

- **32-битная UEFI при 64-битном процессоре.** В образе должен быть `EFI/boot/bootia32.efi`. **В Debian 12 netinst он есть, в Debian 13 его нет.**
- **Внутренняя память называется `mmcblk1`**, а не `mmcblk0`.
- **Прошивка не добавляет Debian в порядок загрузки сама**, поэтому после установки появляется «No bootable device». Это исправляет шаг 5.
- **Единственный порт — micro-USB OTG.** Нужен OTG-хаб. Если в нём одновременно флешка, клавиатура и Ethernet, лучше с отдельным питанием.

## 1. Подготовка

- **Образ:** [`debian-12.15.0-amd64-netinst.iso`](https://cdimage.debian.org/cdimage/archive/12.15.0/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso)
  SHA256 `cd4462c06aa8892e692c0c4b9c17802f38c8ab8690e85cbfb5ccaa5956e9af17`
- **Запись через Rufus:** схема **GPT**, цель **UEFI (non-CSM)**, на вопрос про образ выбери **режим DD**. Ventoy не используй: установщик падал на копировании файлов.
- **Понадобятся USB-клавиатура и USB-Ethernet адаптер.** Wi-Fi в установщике не подключился.

## 2. BIOS

1. Включи планшет, удерживая **Громкость +**.
2. **Security:** задай **Supervisor Password**. Без него остальные пункты заблокированы.
3. **Boot:** **Secure Boot** переключи в **Disabled**, а **USB HDD** поставь первым.
4. Нажми **F10**, чтобы сохранить.

## 3. Установка

1. Загрузись с флешки и выбери **Install**.
2. **Сеть:**
   - подключи Ethernet-адаптер до шага обнаружения сети и выбери `eth0` или `enx…`;
   - на вопрос о недостающей прошивке ответь «Нет».
3. **Разметка:** «Авто — использовать весь диск», диск **`mmcblk1`**, все файлы в одном разделе.
4. **Программы:** **Xfce**, **SSH server** и стандартные утилиты. Сними GNOME: он слишком тяжёлый для 1 ГБ ОЗУ.
5. Шаг «Configuring linux-image…» длится 10–30 минут, это нормально.
6. Перезагрузись. На этом этапе ожидаемо будет «No bootable device».

## 4. Режим восстановления

1. Загрузись с флешки и выбери **Advanced options → Rescue mode**.
2. Пропусти настройку сети:
   - «Вернуться» → «Не настраивать сеть сейчас»;
   - или добавь `netcfg/enable=false` в строку ядра (клавиша `e` в меню).
3. **Корневой раздел:** `/dev/mmcblk1p2`.
4. Монтировать `/boot/efi`: **Yes**.
5. Выбери **Execute a shell in /dev/mmcblk1p2**.

## 5. Починка «No bootable device»

```sh
grub-install --target=i386-efi --efi-directory=/boot/efi --force-extra-removable
update-grub
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
efibootmgr -v
```

В выводе найди две записи:
- **`Unknown Device`**: `PciRoot(0x0)/Pci(0x17,0x0)/…/HD(1,GPT,…)`
- **`debian`**: `…\EFI\debian\grubia32.efi`

Записи существуют, но их нет в `BootOrder`. Поставь их первыми, со своими номерами и **без пробелов**:

```sh
efibootmgr -o 0001,0002,2001,2002,2003
```

Затем `exit`, перезагрузка, вытащи флешку. Debian загрузится.

Если записи `Unknown Device` нет, добавь файл через BIOS:
1. Временно включи Secure Boot.
2. В Security выбери **Select an UEFI file as trusted** → `HDD0/EFI/debian/grubia32.efi`.
3. Снова выключи Secure Boot.

## 6. Настройка после установки

Подключи Ethernet, войди в систему и выполни:

```sh
sudo apt install git
git clone https://github.com/disasmic/acer-iconia-w1-810-linux.git
cd acer-iconia-w1-810-linux
sudo ./setup.sh
sudo reboot
# после входа в рабочий стол:
./setup-user.sh
```

**Нет `sudo`?** Если при установке задан пароль root, пользователь не попадает в группу `sudo`. Добавь его так:
```sh
su - -c "/usr/sbin/usermod -aG sudo $USER"
```
Потом войди в систему заново.

`setup.sh` (от root):
- ставит прошивки и утилиты;
- настраивает NVRAM для Wi-Fi и патч Bluetooth с проверкой SHA256;
- включает zram, калибровку тачскрина, службу долгого тапа и автоповорот;
- включает клавиатуру на экране входа и поддержку специальных возможностей в Firefox.

`setup-user.sh` (в сессии):
- двойной тап под палец: 30 пикселей и 500 мс вместо 5 пикселей и 400 мс;
- настройки автопоказа onboard.

Затем подключись к Wi-Fi через значок на панели.

## Заметки

- **Калибровка тачскрина** в `config/99-touch-calibration.rules` снята с одного экземпляра (она убирала сдвиг около 12 пикселей по вертикали). Если на твоём планшете касания неточные, запусти `xinput_calibrator -v`, возьми координаты четырёх касаний и рассчитай свою `LIBINPUT_CALIBRATION_MATRIX`. Или просто удали правило.
- **Долгий тап** даёт правый клик, когда **отпускаешь** палец после удержания на месте 0,6 секунды.
- **Автопоказ onboard** требует `tablet-mode-detection-enabled=false`. Иначе клавиатура ждёт переключателя «режим планшета», которого у этого устройства нет.
- **Файлов прошивок в репозитории нет.** Они берутся из пакетов Debian, а патч Bluetooth скачивается из [LibreELEC/brcmfmac_sdio-firmware](https://github.com/LibreELEC/brcmfmac_sdio-firmware).
