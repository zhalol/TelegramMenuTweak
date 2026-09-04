# Инструкция после установки WSL

## Шаг 1: Перезагрузите компьютер
После команды `wsl --install` обязательно перезагрузите Windows.

## Шаг 2: Первый запуск Ubuntu
1. Откройте меню Пуск
2. Найдите и запустите **Ubuntu** (или **WSL**)
3. При первом запуске подождите 1-2 минуты (установка завершается)
4. Вас попросят создать пользователя:
   - Введите имя пользователя (латиницей, например: jalol)
   - Введите пароль (будет использоваться для sudo)
   - Пароль не отображается при вводе - это нормально!

## Шаг 3: Обновите систему
В терминале Ubuntu выполните:
```bash
sudo apt update
sudo apt upgrade -y
```

## Шаг 4: Установите необходимые инструменты
```bash
sudo apt install -y git make perl curl zip unzip build-essential
```

## Шаг 5: Установите Theos
```bash
export THEOS=~/theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

Добавьте Theos в PATH:
```bash
echo 'export THEOS=~/theos' >> ~/.bashrc
echo 'export PATH=$THEOS/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Шаг 6: Перейдите в папку проекта
```bash
cd /mnt/c/Users/Жалол/Desktop/WSC/11.5/TelegramMenuTweak
```

## Шаг 7: Скомпилируйте проект
```bash
make clean
make package
```

## Шаг 8: Скопируйте готовую dylib
```bash
cp .theos/obj/debug/TelegramMenuTweak.dylib ./TelegramMenuTweak.dylib
ls -lh TelegramMenuTweak.dylib
```

Если вы видите размер файла - компиляция успешна! ✅

## Готовый файл будет здесь:
```
C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\TelegramMenuTweak.dylib
```

---

## ИЛИ: Просто запустите compile.bat

Вместо всех шагов выше, просто:
1. Закройте все окна WSL/Ubuntu
2. Двойной клик на файл:
   ```
   C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\compile.bat
   ```
3. Скрипт сделает всё автоматически

---

## Возможные проблемы:

### "WSL не установлен" после перезагрузки
Попробуйте:
```powershell
wsl --update
wsl --set-default-version 2
```

### "Permission denied" при компиляции
```bash
chmod +x build.sh
sudo chmod -R 755 ~/theos
```

### Ошибка "SDK not found"
```bash
cd ~/theos
git clone https://github.com/theos/sdks.git sdks
```

---

## После получения dylib:

### Следующий шаг - инжект в IPA:

1. **Простой способ - Sideloadly:**
   - Скачайте: https://sideloadly.io/
   - Откройте IPA файл
   - Advanced Options → Inject dylibs → выберите TelegramMenuTweak.dylib
   - Start

2. **Или вручную:**
   ```bash
   # В WSL:
   cd /mnt/c/Users/Жалол/Desktop/WSC/11.5
   ./TelegramMenuTweak/inject.sh
   ```

Готовый модифицированный IPA будет: `11.5_modified.ipa`
