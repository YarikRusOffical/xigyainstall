#!/usr/bin/env bash

# XIGYA Hybrid Installer
# Старт: xigyainstall

# === 1. Выбор языка ===
choose_language() {
    clear
    # Сначала включаем кириллицу, чтобы не было квадратиков
    setfont cyr-sun16 2>/dev/null

    echo "Select language / Выберите язык:"
    echo "1) English"
    echo "2) Русский"
    read -p "> " lang_choice

    case "$lang_choice" in
        1) LANG_CHOICE="en"; setfont lat9-16 2>/dev/null ;; # возвращаем латиницу
        2) LANG_CHOICE="ru" ;; # остаёмся на кириллице
        *) LANG_CHOICE="en"; setfont lat9-16 2>/dev/null ;;
    esac
}

say() {
    if [ "$LANG_CHOICE" = "ru" ]; then
        case "$1" in
            "check_net") echo "Проверка интернет-соединения..." ;;
            "eth_found") echo "Ethernet-соединение обнаружено" ;;
            "eth_not") echo "Ethernet не найден, необходимо настроить Wi-Fi" ;;
            "wifi_setup") echo "Запуск настройки Wi-Fi..." ;;
        esac
    else
        case "$1" in
            "check_net") echo "Checking internet connection..." ;;
            "eth_found") echo "Ethernet connection detected" ;;
            "eth_not") echo "No Ethernet detected, Wi-Fi setup required" ;;
            "wifi_setup") echo "Starting Wi-Fi setup..." ;;
        esac
    fi
}

# === Новый этап: Приветствие и выбор режима ===
welcome_screen() {
    clear
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo -e "\e[1;32mДобро пожаловать в установку Xigya Linux!\e[0m"
        echo
        echo "Вы можете:"
        echo " - Написать \e[1;36mskip\e[0m чтобы продолжить стандартную установку"
        echo " - Написать \e[1;36msettings\e[0m чтобы настроить параметры перед установкой"
        echo
        read -p "> " INSTALL_MODE
    else
        echo -e "\e[1;32mWelcome to Xigya Linux installation!\e[0m"
        echo
        echo "You can:"
        echo " - Type \e[1;36mskip\e[0m to continue with standard installation"
        echo " - Type \e[1;36msettings\e[0m to configure options before installation"
        echo
        read -p "> " INSTALL_MODE
    fi

    case "$INSTALL_MODE" in
        skip|Skip|SKIP)
            [ "$LANG_CHOICE" = "ru" ] && echo "Запуск стандартной установки..." || echo "Starting standard installation..."
            ;;
        settings|Settings|SETTINGS)
            if [ "$LANG_CHOICE" = "ru" ]; then
                echo "=== Настройки установки ==="
                echo "1) Выбор окружения рабочего стола"
                echo "2) Выбор набора пакетов"
                echo "3) Ручной выбор региона/языка"
                echo "(Пока это демо, позже можно расширить)"
            else
                echo "=== Installation settings ==="
                echo "1) Choose desktop environment"
                echo "2) Choose package set"
                echo "3) Manual region/language selection"
                echo "(For now this is a demo, can be expanded later)"
            fi
            # Тут можно будет добавить реальную логику (например меню выбора DE, пакетов и т.д.)
            ;;
        *)
            [ "$LANG_CHOICE" = "ru" ] && echo "Неверный ввод, продолжаем стандартную установку..." || echo "Invalid input, continuing with standard installation..."
            ;;
    esac
}


# === 2. Проверка и настройка сети ===
setup_network() {
    say check_net
    if ping -c 1 google.com &>/dev/null; then
        say eth_found
        return
    fi

    say eth_not

    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Выберите способ подключения Wi-Fi:"
        echo "1) Автоматическое (указать SSID и пароль)"
        echo "2) Вручную (запустить iwctl)"
    else
        echo "Choose Wi-Fi connection method:"
        echo "1) Automatic (enter SSID and password)"
        echo "2) Manual (open iwctl)"
    fi
    read -p "> " wifi_choice

    case "$wifi_choice" in
        1)
            if [ "$LANG_CHOICE" = "ru" ]; then
                read -p "Введите SSID, это название вашей сети Wi-Fi: " WIFI_SSID
                read -sp "Введите пароль: " WIFI_PASS
                echo
            else
                read -p "Enter SSID, this is the name of your Wi-Fi network: " WIFI_SSID
                read -sp "Enter password: " WIFI_PASS
                echo
            fi

            # Находим адаптер (берем первый wlan*)
            WIFI_DEV=$(iwctl device list | awk '/wlan/{print $2; exit}')
            if [ -n "$WIFI_DEV" ]; then
                iwctl --passphrase "$WIFI_PASS" station "$WIFI_DEV" connect "$WIFI_SSID"
                if ping -c 1 google.com &>/dev/null; then
                    [ "$LANG_CHOICE" = "ru" ] && echo "Wi-Fi подключен :)" || echo "Wi-Fi connected :)"
                else
                    [ "$LANG_CHOICE" = "ru" ] && echo "Ошибка подключения :(" || echo "Connection failed :("
                fi
            else
                [ "$LANG_CHOICE" = "ru" ] && echo "Wi-Fi адаптер не найден" || echo "No Wi-Fi adapter found"
            fi
            ;;
        2)
            say wifi_setup
            iwctl
            ;;
        *)
            [ "$LANG_CHOICE" = "ru" ] && echo "Неверный выбор, запускаем iwctl..." || echo "Invalid choice, starting iwctl..."
            iwctl
            ;;
    esac
}

# === 3. Настройка пакетного менеджера ===
setup_pacman() {
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo -e "\e[1;34mНастройка pacman...\e[0m"
        read -p "Сколько одновременных загрузок (ParallelDownloads) вы хотите установить? " PARALLEL
    else
        echo -e "\e[1;34mConfiguring pacman...\e[0m"
        read -p "How many simultaneous downloads (ParallelDownloads) do you want? " PARALLEL
    fi

    if [ -f /etc/pacman.conf ]; then
        sed -i "s/^#ParallelDownloads = .*/ParallelDownloads = $PARALLEL/" /etc/pacman.conf
        [ "$LANG_CHOICE" = "ru" ] && echo "Pacman настроен" || echo "Pacman configured"
    else
        [ "$LANG_CHOICE" = "ru" ] && echo "Файл /etc/pacman.conf не найден" || echo "/etc/pacman.conf not found"
    fi
}

# === 4. Разметка диска ===
partition_disk() {
    # Предупреждение
    echo
    echo -e "\e[1;31mВНИМАНИЕ!\e[0m"
    echo -e "\e[1;37mНачиная этап разметки диска, вы должны разметить свободное место так:"
    echo "1) EFI system на 512 МБ, Linux filesystem на всё остальное"
    echo "2) EFI system на 512 МБ, Linux filesystem(Система) на 32GB и Linux filesystem(папка пользователя) на остальное"
    echo
    echo "Если вы потеряли данные из-за новой разметки, установщик и его создатели НЕ НЕСУТ ОТВЕТСТВЕННОСТИ!"
    echo

    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Вы точно хотите разметить диск? (Да/Нет): " CONFIRM
    else
        read -p "Do you really want to partition the disk? (Yes/No): " CONFIRM
    fi

    case "$CONFIRM" in
        да|Да|Y|y|Yes|yes)
            if [ "$LANG_CHOICE" = "ru" ]; then
                echo "Выберите способ разметки:"
                echo "1) Найти диск автоматически"
                echo "2) Ввести диск вручную"
            else
                echo "Choose partitioning method:"
                echo "1) Find disk automatically"
                echo "2) Enter disk manually"
            fi
            read -p "> " PART_CHOICE

            case "$PART_CHOICE" in
                1)
                    # Автоматический поиск диска (берем первый non-USB/ISO диск)
                    DISK=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print "/dev/" $1; exit}')
                    [ "$LANG_CHOICE" = "ru" ] && echo "Найден диск: $DISK" || echo "Found disk: $DISK"
					if [ "$LANG_CHOICE" = "ru" ]; then
						read -t 5 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 5 секунд..."
					else
						read -t 5 -n 1 -s -r -p "Press any key to continue or wait 5 seconds..."
					fi
					echo
                    cfdisk "$DISK"
                    ;;
                2)
					lsblk
                    if [ "$LANG_CHOICE" = "ru" ]; then
                        read -p "Впишите правильный диск (например sda): " DISK
                    else
                        read -p "Enter the correct disk (e.g., sda): " DISK
                    fi
                    [ "$LANG_CHOICE" = "ru" ] && echo "Указан диск: $DISK" || echo "Specified disk: $DISK"
					if [ "$LANG_CHOICE" = "ru" ]; then
						read -t 5 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 5 секунд..."
					else
						read -t 5 -n 1 -s -r -p "Press any key to continue or wait 5 seconds..."
					fi
					echo
                    cfdisk "/dev/$DISK"
                    ;;
                *)
                    [ "$LANG_CHOICE" = "ru" ] && echo "Неверный выбор, завершение установки" || echo "Invalid choice, exiting installation"
                    exit 1
                    ;;
            esac
            ;;
        *)
            [ "$LANG_CHOICE" = "ru" ] && echo "Отмена разметки, завершение установки" || echo "Partitioning canceled, exiting installation"
            exit 1
            ;;
    esac
}
# === 5. Форматирование разделов ===
format_partitions() {
    echo
    # Предупреждение
    echo -e "\e[1;31mВНИМАНИЕ!\e[0m"
    echo -e "\e[1;37mВсе указанные в этапе форматирования диски будут отформатированы!"
    echo "Все файлы на них будут удалены и форматированы."
    echo "Если вы потеряете данные, установщик и его разработчики НЕ НЕСУТ ОТВЕТСТВЕННОСТИ!"
    echo

    # Показать список дисков
    lsblk
    echo

    # Ввод EFI-диска
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите диск, который будет использоваться для EFI (например sda1): " EFI_DISK
    else
        read -p "Enter the disk to use for EFI (e.g., sda1): " EFI_DISK
    fi

    # Ввод системного диска
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите диск, который будет использоваться для системного раздела (например sda2): " ROOT_DISK
    else
        read -p "Enter the disk to use for root system (e.g., sda2): " ROOT_DISK
    fi

    # Проверка, есть ли домашний раздел
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Есть ли отдельный раздел для /home? (Да/Нет): " HOME_ANSWER
    else
        read -p "Is there a separate partition for /home? (Yes/No): " HOME_ANSWER
    fi

    if [[ "$HOME_ANSWER" =~ ^(да|Да|Y|y|Yes|yes)$ ]]; then
        if [ "$LANG_CHOICE" = "ru" ]; then
            read -p "Введите диск для /home (например sda3): " HOME_DISK
        else
            read -p "Enter the disk for /home (e.g., sda3): " HOME_DISK
        fi
    fi

    echo
    # Форматирование
    echo "Форматируем разделы..."
    mkfs.vfat "/dev/$EFI_DISK"
    mkfs.ext4 "/dev/$ROOT_DISK"
    if [ -n "$HOME_DISK" ]; then
        mkfs.ext4 "/dev/$HOME_DISK"
    fi

    [ "$LANG_CHOICE" = "ru" ] && echo "Разделы успешно отформатированы" || echo "Partitions formatted successfully"
}

# === 6. Монтирование разделов ===
mount_partitions() {
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Монтируем разделы..." || echo "Mounting partitions..."

    echo "mount /dev/$ROOT_DISK /mnt"
    mount "/dev/$ROOT_DISK" /mnt

    echo "mkdir -p /mnt/boot/efi"
    mkdir -p /mnt/boot/efi

    echo "mount /dev/$EFI_DISK /mnt/boot/efi"
    mount "/dev/$EFI_DISK" /mnt/boot/efi

    if [ -n "$HOME_DISK" ]; then
        echo "mkdir -p /mnt/home"
        mkdir -p /mnt/home

        echo "mount /dev/$HOME_DISK /mnt/home"
        mount "/dev/$HOME_DISK" /mnt/home
    fi

    [ "$LANG_CHOICE" = "ru" ] && echo "Разделы смонтированы успешно" || echo "Partitions mounted успешно"
}

# === 7. Установка пакетов ===
install_packages() {
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Начинаем установку пакетов..." || echo "Starting package installation..."

    BASE_PACKAGES="base base-devel linux linux-firmware linux-headers nano vim bash-completion grub efibootmgr"
    FONTS="ttf-ubuntu-font-family ttf-hack ttf-dejavu ttf-opensans"
    XORG="xorg"
    NETWORK="networkmanager"
	[ "$LANG_CHOICE" = "ru" ] && echo "База = $BASE_PACKAGES" || echo "Base = $BASE_PACKAGES"
	echo "Xorg = $XORG"
	[ "$LANG_CHOICE" = "ru" ] && echo "Шрифты = $FONTS" || echo "Шрифты = $FONTS"
	[ "$LANG_CHOICE" = "ru" ] && echo "Интернет = $NETWORK" || echo "Network = $NETWORK"

    # Дисплейный менеджер
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Выберите дисплейный менеджер:"
        echo "1) gdm"
        echo "2) lightdm"
    else
        echo "Choose display manager:"
        echo "1) gdm"
        echo "2) lightdm"
    fi
    read -p "> " DM_CHOICE

    case "$DM_CHOICE" in
        1) DM="gdm" ;;
        2) DM="lightdm lightdm-gtk-greeter" ;;
        *) DM="lightdm lightdm-gtk-greeter" ;;
    esac

    # Окружение (пока только xfce4)
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Выберите окружение:"
        echo "1) xfce4"
        echo "2) gnome"
		echo "3) KDE Plasma"
    else
        echo "Choose Linux interface:"
        echo "1) xfce4"
        echo "2) gnome"
		echo "3) KDE Plasma"
    fi
    read -p "> " DESKTOP_CHOICE

    case "$DESKTOP_CHOICE" in
        *) DESKTOP="xfce4" ;;
    esac

    # Драйвер NVIDIA
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Установить драйвер NVIDIA? (Да/Нет): " NVIDIA_CHOICE
    else
        read -p "Install NVIDIA driver? (Yes/No): " NVIDIA_CHOICE
    fi
    if [[ "$NVIDIA_CHOICE" =~ ^(Да|Y|y|Yes|yes)$ ]]; then
        NVIDIA="nvidia"
    else
        NVIDIA=""
    fi

    # Команда pacstrap
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Выполняем: $PACSTRAP_CMD" || echo "Executing: $PACSTRAP_CMD"
    PACSTRAP_CMD="pacstrap /mnt $BASE_PACKAGES $FONTS $XORG $NETWORK $DM $DESKTOP $NVIDIA"
    echo "$PACSTRAP_CMD"
	if [ "$LANG_CHOICE" = "ru" ]; then
		read -t 15 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 15 секунд..."
	else
		read -t 15 -n 1 -s -r -p "Press any key to continue or wait 15 seconds..."
	fi
	echo
    $PACSTRAP_CMD

    [ "$LANG_CHOICE" = "ru" ] && echo "Пакеты установлены" || echo "Packages installed"
}

# === 8. Генерация fstab, chroot и включение сервисов ===
post_install() {
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Генерируем fstab..." || echo "Generating fstab..."
    echo "genfstab -U /mnt >> /mnt/etc/fstab"
    genfstab -U /mnt >> /mnt/etc/fstab

    [ "$LANG_CHOICE" = "ru" ] && echo "Входим в установленную систему (arch-chroot)..." || echo "Entering installed system (arch-chroot)..."

    # Определяем дисплейный менеджер для chroot скрипта
    CHROOT_DM="$DM"

    # Скрипт для выполнения в chroot
    CHROOT_SCRIPT="/mnt/root/post_chroot.sh"

    cat > "$CHROOT_SCRIPT" <<EOF
#!/usr/bin/env bash

echo "Enabling NetworkManager..."
systemctl enable NetworkManager

echo "Enabling display manager..."
if [[ "$CHROOT_DM" == *"gdm"* ]]; then
    systemctl enable gdm
elif [[ "$CHROOT_DM" == *"lightdm"* ]]; then
    systemctl enable lightdm
fi

echo "All done inside chroot!"
EOF

    chmod +x "$CHROOT_SCRIPT"

    # Передаем переменную DM в chroot через окружение
    arch-chroot /mnt /bin/bash -c "CHROOT_DM='$CHROOT_DM' /root/post_chroot.sh"

    # Удаляем временный скрипт
    rm /mnt/root/post_chroot.sh

    [ "$LANG_CHOICE" = "ru" ] && echo "Почти готово, продолжай в том же духе." || echo "Almost there, just keep going."
}

# === 8.1. Включение Bluetooth ===
setup_bluetooth() {
    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Хотите включить поддержку Bluetooth? (Да/Нет): " BT_ANSWER
    else
        read -p "Do you want to enable Bluetooth support? (Yes/No): " BT_ANSWER
    fi

    if [[ "$BT_ANSWER" =~ ^(да|Да|Y|y|Yes|yes)$ ]]; then
        echo "systemctl enable bluetooth"
        systemctl enable bluetooth
        [ "$LANG_CHOICE" = "ru" ] && echo "Bluetooth включён" || echo "Bluetooth enabled"
    else
        [ "$LANG_CHOICE" = "ru" ] && echo "Bluetooth пропущен" || echo "Bluetooth skipped"
    fi
}

# === 9. Создание учетной записи пользователя и настройка паролей ===
create_user() {
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Создание пользователя..." || echo "Creating user account..."

    # Ввод никнейма
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите свой никнейм: " NEW_USER
    else
        read -p "Enter your username: " NEW_USER
    fi

    # Создаем пользователя с домашним каталогом
    useradd -m "$NEW_USER"

    # Пароль пользователя
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo -e "\nВнимание! Если вы забудете пароль пользователя, потребуется переустановка системы!"
        echo "Вы сейчас будете вводить пароль для пользователя $NEW_USER"
    else
        echo -e "\nWarning! If you forget the user password, you may need to reinstall the system!"
        echo "You will now enter the password for user $NEW_USER"
    fi
    passwd "$NEW_USER"

    # Пароль root
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo -e "\nВы будете вводить пароль для root-аккаунта. Рекомендуется надёжный пароль!"
        echo "Вы сейчас будете вводить пароль для root"
    else
        echo -e "\nYou will now enter a password for the root account. Make it strong!"
        echo "You will now enter the root password"
    fi
    passwd root

    # Настройка sudo
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Выдать права sudo пользователю $NEW_USER? (Да/Нет): " SUDO_ANSWER
    else
        read -p "Grant sudo privileges to $NEW_USER? (Yes/No): " SUDO_ANSWER
    fi

    if [[ "$SUDO_ANSWER" =~ ^(да|Да|Y|y|Yes|yes)$ ]]; then
        if [ "$LANG_CHOICE" = "ru" ]; then
            echo "Выберите способ выдачи sudo:" 
            echo "1) Автоматически"
            echo "2) Вручную через nano /etc/sudoers или visudo"
        else
            echo "Choose sudo setup method:"
            echo "1) Automatically"
            echo "2) Manually via nano /etc/sudoers or visudo"
        fi
        read -p "> " SUDO_METHOD

        case "$SUDO_METHOD" in
            1)
                usermod -aG wheel "$NEW_USER"
                sed -i 's/^# \(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers
                ;;
            2)
                [ "$LANG_CHOICE" = "ru" ] && echo "После установки откройте sudoers вручную" || echo "You can edit sudoers manually after installation"
                ;;
        esac
    fi

    [ "$LANG_CHOICE" = "ru" ] && echo "Пользователь $NEW_USER создан и настроен" || echo "User $NEW_USER created and configured"
}

# === 10. Настройка локали ===
setup_locale() {
    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Настройка локали системы..."
        echo "Выберите способ настройки:"
        echo "1) Вручную"
        echo "2) Автоматически"
    else
        echo "System locale setup..."
        echo "Choose setup method:"
        echo "1) Manual"
        echo "2) Automatic"
    fi
    read -p "> " LOCALE_METHOD

    case "$LOCALE_METHOD" in
        1)  # Ручной режим
            if [ "$LANG_CHOICE" = "ru" ]; then
                echo -e "\nСейчас откроется файл /etc/locale.gen для расскоментирования нужных локалей (например ru_RU.UTF-8 UTF-8)"
                read -t 10 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 10 секунд..."
            else
                echo -e "\nThe file /etc/locale.gen will be opened. Uncomment the locales you need (e.g., ru_RU.UTF-8 UTF-8)"
                read -t 10 -n 1 -s -r -p "Press any key to continue or wait 10 seconds..."
            fi
            nano /etc/locale.gen

            if [ "$LANG_CHOICE" = "ru" ]; then
                echo -e "\nТеперь откроется файл /etc/locale.conf, где нужно указать LANG=ваша_локаль (например: LANG=ru_RU.UTF-8)"
                read -t 10 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 10 секунд..."
            else
                echo -e "\nNow edit /etc/locale.conf and set LANG=your_locale (e.g., LANG=ru_RU.UTF-8)"
                read -t 10 -n 1 -s -r -p "Press any key to continue or wait 10 seconds..."
            fi
            nano /etc/locale.conf

            locale-gen
            ;;

        2)  # Автоматический режим
            if [ "$LANG_CHOICE" = "ru" ]; then
                echo "Выберите локали для установки, Английский включён по умолчанию:"
                echo "1) Только английский"
                echo "2) Русский"
                echo "3) Немецкий"
                echo "4) Французский"
            else
                echo "Choose locales to install, English enabled by default:"
                echo "1) English only"
                echo "2) Russian"
                echo "3) German"
                echo "4) French"
            fi
            read -p "> " AUTO_LOCALE

            # По умолчанию английский
            LOCALES_TO_ENABLE="en_US.UTF-8 UTF-8"

            case "$AUTO_LOCALE" in
                1) LOCALES_TO_ENABLE="en_US.UTF-8 UTF-8" ;;
                2) LOCALES_TO_ENABLE="ru_RU.UTF-8 UTF-8 en_US.UTF-8 UTF-8" ;;
                3) LOCALES_TO_ENABLE="de_DE.UTF-8 UTF-8 en_US.UTF-8 UTF-8" ;;
                4) LOCALES_TO_ENABLE="fr_FR.UTF-8 UTF-8 en_US.UTF-8 UTF-8" ;;
            esac

            # Расскоментирование локалей в locale.gen
            for loc in $LOCALES_TO_ENABLE; do
                sed -i "s/^#\s*$loc/$loc/" /etc/locale.gen
            done

            if [ "$LANG_CHOICE" = "ru" ]; then
                echo "Какой язык сделать основным?"
                echo "1) Английский"
                echo "2) Выбранный ранее"
            else
                echo "Which locale to set as default?"
                echo "1) English"
                echo "2) Other selected locale"
            fi
            read -p "> " DEFAULT_LANG_CHOICE

            case "$DEFAULT_LANG_CHOICE" in
                1) DEFAULT_LANG="en_US.UTF-8" ;;
                2) 
                    case "$AUTO_LOCALE" in
                        1) DEFAULT_LANG="en_US.UTF-8" ;;
                        2) DEFAULT_LANG="ru_RU.UTF-8" ;;
                        3) DEFAULT_LANG="de_DE.UTF-8" ;;
                        4) DEFAULT_LANG="fr_FR.UTF-8" ;;
                    esac
                    ;;
                *) DEFAULT_LANG="en_US.UTF-8" ;;
            esac

            echo "LANG=$DEFAULT_LANG" > /etc/locale.conf
            locale-gen
            ;;
        *)
            echo "Invalid choice, skipping locale setup..."
            ;;
    esac

    [ "$LANG_CHOICE" = "ru" ] && echo "Язык настроен" || echo "Language configured"
}

# === 11. Установка и настройка GRUB ===
setup_grub() {
    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Установка загрузчика GRUB..."
        echo "Выберите режим прошивки вашего ПК:"
        echo "1) UEFI"
        echo "2) BIOS"
    else
        echo "GRUB bootloader setup..."
        echo "Select your firmware type:"
        echo "1) UEFI"
        echo "2) BIOS"
    fi
    read -p "> " GRUB_MODE

    # Определяем диск для установки GRUB
    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите диск для установки GRUB (например sda): " GRUB_DISK
    else
        read -p "Enter the disk to install GRUB (e.g., sda): " GRUB_DISK
    fi

    case "$GRUB_MODE" in
        1)  # UEFI
            echo "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB /dev/$GRUB_DISK"
            grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB "/dev/$GRUB_DISK"
            ;;
        2)  # BIOS
            echo "grub-install --target=i386-pc /dev/$GRUB_DISK"
            grub-install --target=i386-pc "/dev/$GRUB_DISK"
            ;;
        *)
            echo "Invalid choice, skipping GRUB installation..."
            return
            ;;
    esac

    # Редактирование параметра quiet
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Хотите убрать параметр 'quiet' из GRUB_CMDLINE_LINUX_DEFAULT?"
        echo "1) Вручную через nano"
        echo "2) Сделать автоматически"
    else
        echo "Do you want to remove the 'quiet' parameter from GRUB_CMDLINE_LINUX_DEFAULT?"
        echo "1) Manually via nano"
        echo "2) Automatically"
    fi
    read -p "> " QUIET_CHOICE

    case "$QUIET_CHOICE" in
        1)
            nano /etc/default/grub
            ;;
        2)
            sed -i 's/quiet//g' /etc/default/grub
            ;;
        *)
            echo "Skipping modification of GRUB_CMDLINE_LINUX_DEFAULT..."
            ;;
    esac

    # Генерация конфигурации GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    [ "$LANG_CHOICE" = "ru" ] && echo "GRUB установлен и настроен" || echo "GRUB installed and configured"
}
# === 11.1. Настройка часового пояса ===
setup_timezone() {
    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo "Сейчас настроим часовой пояс. Это последний этап."
        echo "Если хотите пропустить настройку, введите: skip"
    else
        echo "Now let's configure your timezone. This is the last stage."
        echo "If you want to skip, type: skip"
    fi

    # Список регионов
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Доступные регионы:" || echo "Available regions:"
    ls /usr/share/zoneinfo | grep -v 'posix' | grep -v 'right' | grep -v 'zone.tab' | grep -v 'zone1970.tab' | grep -v 'Etc'

    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите регион (например Asia) или skip: " REGION
    else
        read -p "Enter region (e.g., Europe) or skip: " REGION
    fi

    if [ "$REGION" = "skip" ]; then
        [ "$LANG_CHOICE" = "ru" ] && echo "Настройка часового пояса пропущена" || echo "Timezone setup skipped"
        return
    fi

    # Список городов
    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Доступные города для $REGION:" || echo "Available cities for $REGION:"
    ls "/usr/share/zoneinfo/$REGION"

    if [ "$LANG_CHOICE" = "ru" ]; then
        read -p "Введите город (например Yekaterinburg): " CITY
    else
        read -p "Enter city (e.g., London): " CITY
    fi

    TIMEZONE="$REGION/$CITY"

    if [ -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
        ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
        hwclock --systohc
        [ "$LANG_CHOICE" = "ru" ] && echo "Часовой пояс настроен на $TIMEZONE" || echo "Timezone set to $TIMEZONE"
    else
        [ "$LANG_CHOICE" = "ru" ] && echo "Ошибка: $TIMEZONE не найден" || echo "Error: $TIMEZONE not found"
    fi
}

# === 12. Финальное сообщение и перезагрузка ===
final_message() {
    echo
    if [ "$LANG_CHOICE" = "ru" ]; then
        echo -e "\e[1;32mПоздравляем! Установка завершена успешно!\e[0m"
        echo "Обращаюсь к тебе пользователь. Я рад что ты прошёл через наш новый собственный установщик Xigya Linux, он объединил вручной и archinstall способ. Добро пожаловать в наше сообщество Xigya Linux, ты всегда лучший из лучших! Спасибо!"
        echo "-YarikRus, основатель Xigya Linux и скрипта-установщика для Xigya Linux"
		echo -e "\e[33mПосле перезагрузки, отключите флешку или CD/DVD.\e[0m"
        read -t 600 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 10 минут..."
    else
        echo -e "\e[1;32mCongratulations! Installation is complete!\e[0m"
        echo "I’m addressing you, user. I’m glad you’ve gone through our new custom Xigya Linux installer, which combines the manual method and archinstall. Welcome to the Xigya Linux community — you are always the best of the best! Thank you!"
        echo "-YarikRus, founder of Xigya Linux and the Xigya Linux installer script"
		echo -e "\e[33mAfter rebooting, disconnect the flash drive or CD/DVD\e[0m"
        read -t 600 -n 1 -s -r -p "Press any key to continue or wait 10 minutes..."
    fi

    echo
    [ "$LANG_CHOICE" = "ru" ] && echo "Выходим из chroot, размонтируем разделы и перезагружаем систему..." || echo "Exiting chroot, unmounting partitions, and rebooting..."
	if [ "$LANG_CHOICE" = "ru" ]; then
        read -t 600 -n 1 -s -r -p "Нажмите любую клавишу чтобы продолжить или подождите 5 секунд..."
    else
        read -t 600 -n 1 -s -r -p "Press any key to continue or wait 5 seconds..."
    fi
    
	exit
    # Размонтируем все смонтированные разделы
    umount -R /mnt
    
    # Перезагрузка системы
    reboot
}


# === Главный блок ===
main() {
    choose_language
	welcome_screen
    setup_network
    setup_pacman
    partition_disk
    format_partitions
    mount_partitions
    install_packages
    post_install
    setup_bluetooth
    create_user
    setup_locale
    setup_grub
    setup_timezone
    final_message
}

main
