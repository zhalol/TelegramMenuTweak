# ИНСТРУКЦИЯ ДЛЯ WINDOWS

## Что я создал для вас

Полный проект твика, который добавляет в Soccer Champs:
- 📱 Плавающую кнопку в правом верхнем углу
- Красивое анимированное меню при нажатии
- Кнопку "📢 Telegram Channel" для перехода на https://t.me/wsciosipa

## Структура проекта

```
TelegramMenuTweak/
├── Tweak.x                    # Исходный код (Objective-C + Logos)
├── Makefile                   # Для компиляции с Theos
├── control                    # Метаданные пакета
├── TelegramMenuTweak.plist   # Привязка к Soccer Champs
├── build.sh                   # Скрипт сборки (Linux/macOS)
├── inject.sh                  # Скрипт автоинжекта (Linux/macOS)
└── README.md                  # Полная документация
```

## ⚠️ ВАЖНО: Компиляция на Windows

К сожалению, **Theos не работает нативно на Windows**. У вас есть 3 варианта:

### ВАРИАНТ 1: Использовать WSL (Windows Subsystem for Linux) ✅ РЕКОМЕНДУЮ

```powershell
# 1. Установите WSL2
wsl --install

# 2. Перезагрузите компьютер

# 3. Откройте Ubuntu из меню Пуск

# 4. В WSL установите Theos:
sudo apt update
sudo apt install git make perl curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 5. Перейдите в папку проекта:
cd /mnt/c/Users/Жалол/Desktop/WSC/11.5/TelegramMenuTweak

# 6. Соберите проект:
chmod +x build.sh
make clean
make package

# 7. Dylib будет здесь:
# .theos/obj/debug/TelegramMenuTweak.dylib
```

### ВАРИАНТ 2: Использовать готовую dylib от другого разработчика

Если у вас есть доступ к Mac или Linux машине (или друга), попросите скомпилировать проект там.

### ВАРИАНТ 3: Использовать виртуальную машину macOS

- Установите VMware/VirtualBox
- Создайте macOS VM
- Соберите там

## Инжект dylib в IPA (после компиляции)

### На Windows (с инструментами)

Вам понадобится:
- **optool** или **insert_dylib** (скомпилированные для Windows)
- 7-Zip или WinRAR

#### Способ А: Вручную

```powershell
# 1. Переименуйте IPA в ZIP и распакуйте
Rename-Item "11.5 (@wscios).ipa" "11.5.zip"
Expand-Archive "11.5.zip" -DestinationPath "extracted"

# 2. Скопируйте вашу скомпилированную dylib в приложение
Copy-Item "TelegramMenuTweak.dylib" "extracted\Payload\Soccer Champs.app\"

# 3. Инжектируйте dylib в исполняемый файл
# (нужен optool.exe или insert_dylib.exe для Windows)
.\optool.exe install -c load -p "@executable_path/TelegramMenuTweak.dylib" -t "extracted\Payload\Soccer Champs.app\Soccer Champs"

# 4. Запакуйте обратно
Compress-Archive -Path "extracted\Payload" -DestinationPath "11.5_modified.zip"
Rename-Item "11.5_modified.zip" "11.5_modified.ipa"

# 5. Подпишите IPA (используйте Sideloadly или AltStore на Windows)
```

#### Способ Б: Использовать Sideloadly (САМЫЙ ПРОСТОЙ) ✅

1. Скачайте **Sideloadly**: https://sideloadly.io/
2. Положите вашу `TelegramMenuTweak.dylib` в папку с IPA
3. В Sideloadly:
   - Выберите ваш IPA файл
   - В "Advanced Options" → "Inject dylibs/frameworks" добавьте вашу dylib
   - Нажмите Start

## Быстрый путь (если у вас есть Jailbreak)

Если ваше устройство с джейлбрейком, вы можете:

1. Собрать `.deb` пакет на Mac/Linux/WSL:
```bash
make package
```

2. Установить через Cydia/Sileo:
```bash
dpkg -i com.wscios.telegrammenu_1.0_iphoneos-arm.deb
killall -9 SpringBoard
```

## Что делает твик

### Визуально:
- Синяя круглая кнопка (60x60) с эмодзи 📱 в правом верхнем углу
- Полупрозрачная с тенью
- При нажатии - анимация появления меню

### Меню содержит:
- Заголовок "WSC IOS"
- Кнопку "📢 Telegram Channel" (синий цвет Telegram)
- Кнопку закрытия (✕) в углу

### При нажатии на кнопку канала:
- Открывается `https://t.me/wsciosipa`
- Если Telegram не установлен - откроется в браузере
- Меню автоматически закрывается

## Технические детали кода

### Как работает инжект:
1. Твик хукает метод `makeKeyAndVisible` класса `UIWindow`
2. Через 2 секунды после запуска добавляется кнопка
3. Используется Logos (препроцессор Theos) для простого хукинга

### Безопасность:
- Использует `@executable_path` - dylib загружается из папки приложения
- Не модифицирует системные файлы
- Работает только с Soccer Champs (фильтр по Bundle ID)

## Нужна помощь?

Если у вас нет возможности скомпилировать dylib, я могу:
1. Дать более подробные инструкции по WSL
2. Объяснить альтернативные методы
3. Помочь с конкретными ошибками компиляции

## Итого - что у вас есть:

✅ Полный исходный код твика (Tweak.x)
✅ Все конфигурационные файлы (Makefile, control, plist)
✅ Скрипты для сборки и инжекта
✅ Подробная документация (README.md)

❌ Скомпилированная dylib (нужен Mac/Linux/WSL для сборки)

---

**Следующий шаг**: Выберите способ компиляции (WSL рекомендуется) или дайте скомпилировать кому-то с Mac.

Telegram: @wsciosipa
