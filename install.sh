#!/bin/bash

# التأكد من أن السكريبت يتم تشغيله كجذر
if [ "$(id -u)" -ne "0" ]; then
    echo "هذا السكريبت يجب أن يُنفذ كجذر"
    exit 1
fi

# عرض الأقراص المتاحة واختيار القرص
echo "الأقراص المتاحة:"
lsblk -d -n -o NAME,SIZE | awk '{print NR ": /dev/" $1 " (" $2 ")"}'

echo "أدخل رقم القرص الذي ترغب في تثبيت النظام عليه (مثلاً 1):"
read CHOICE

# تحديد اسم القرص بناءً على الاختيار
DISK=$(lsblk -d -n -o NAME | sed -n "${CHOICE}p")
DISK="/dev/$DISK"

# التحقق من صحة الإدخال
if [ ! -b "$DISK" ]; then
    echo "الاختيار غير صحيح. يرجى إدخال رقم صحيح."
    exit 1
fi

# تهيئة القرص
echo "تهيئة القرص $DISK"
parted $DISK mklabel gpt
parted $DISK mkpart primary ext4 0% 100%

# إنشاء نظام الملفات
echo "إنشاء نظام الملفات على $DISK"
mkfs.ext4 ${DISK}1

# إنشاء نقطة التثبيت
echo "إنشاء نقطة التثبيت"
mount ${DISK}1 /mnt

# تثبيت النظام الأساسي
echo "تثبيت Arch Linux الأساسية"
pacstrap /mnt base linux linux-firmware

# إنشاء ملف fstab
echo "إنشاء ملف fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# تنفيذ chroot
echo "الدخول إلى نظام chroot"
arch-chroot /mnt /bin/bash <<EOF
    # إعداد الوقت
    timedatectl set-ntp true

    # تثبيت الحزم الأساسية
    pacman -Syu --noconfirm
    pacman -S --noconfirm base-devel git vim networkmanager xorg-setxkbmap

    # إعداد المستخدم
    useradd -m -G wheel -s /bin/bash user
    echo "user:password" | chpasswd
    echo "root:root" | chpasswd

    # تثبيت systemd-boot
    pacman -S --noconfirm dosfstools

    # إعداد systemd-boot
    bootctl --path=/boot install

    # إنشاء ملف التكوين لـ systemd-boot
    echo "title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}1) rw" > /boot/loader/entries/arch.conf

    # تثبيت bspwm و xorg
    pacman -S --noconfirm bspwm sxhkd xorg-server xorg-xinit

    # تثبيت أدوات إضافية
    pacman -S --noconfirm rofi dmenu lxappearance picom polybar ttf-dejavu ttf-liberation xinput

    # إعداد xinitrc
    echo "exec bspwm" > /home/user/.xinitrc

    # إعداد ملف sxhkd
    mkdir -p /home/user/.config/sxhkd
    echo "
# Launch terminal
super + Return
    st

# Launch rofi
super + d
    rofi -show drun

# Launch browser
super + b
    firefox

# Close focused window
super + q
    bspc node -c

# Reload bspwm configuration
super + r
    bspc wm -r

# Switch keyboard layout
super + shift + space
    setxkbmap -layout us,ar -option grp:alt_shift_toggle
    " > /home/user/.config/sxhkd/sxhkdrc

    # إعداد ملف bspwm
    mkdir -p /home/user/.config/bspwm
    echo "
# bspwm config

# General
bspc monitor -d I II III IV V VI VII VIII IX X

# Window border
bspc config border_width 2
bspc config window_gap 10

# Focus behavior
bspc config focus_follows_mouse true
bspc config borderless_monocle true

# Gaps
bspc config top_padding 20
bspc config bottom_padding 20
bspc config left_padding 20
bspc config right_padding 20
    " > /home/user/.config/bspwm/bspwmrc
    chmod +x /home/user/.config/bspwm/bspwmrc

    # إعداد polybar
    mkdir -p /home/user/.config/polybar
    echo "
[bar/example]
width = 100%
height = 30
background = #222222
foreground = #ffffff
border-size = 2
border-color = #ffffff

modules-left = i3
modules-center = date
modules-right = cpu memory

[module/cpu]
type = internal/cpu
format-prefix = CPU:
format-underline = #ff0000

[module/memory]
type = internal/memory
format-prefix = RAM:
format-underline = #00ff00

[module/date]
type = internal/date
format = %Y-%m-%d %H:%M:%S
    " > /home/user/.config/polybar/config

    # إعداد picom
    mkdir -p /home/user/.config/picom
    echo "
# picom config

# Shadow settings
shadow = true;
shadow-radius = 12;
shadow-offset-x = -15;
shadow-offset-y = -15;

# Fading settings
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;
    " > /home/user/.config/picom/picom.conf

    # إعداد ملف xorg.conf.d
    mkdir -p /etc/X11/xorg.conf.d
    echo "
Section \"InputClass\"
    Identifier \"keyboard\"
    MatchIsKeyboard \"on\"
    Option \"XkbLayout\" \"us,ar\"
    Option \"XkbOptions\" \"grp:alt_shift_toggle\"
EndSection
    " > /etc/X11/xorg.conf.d/00-keyboard.conf

    # تمكين خدمة NetworkManager
    systemctl enable NetworkManager

    # إعداد sudo للمستخدم
    pacman -S --noconfirm sudo
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

EOF

# إيقاف المونت والإنهاء
umount -R /mnt
reboot
