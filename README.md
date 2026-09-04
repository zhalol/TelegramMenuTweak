# Telegram Menu Tweak для Soccer Champs

## Описание
Этот твик добавляет перемещаемую плавающую кнопку меню в приложение Soccer Champs, при нажатии на которую открывается красивое меню с кнопкой для перехода на Telegram канал https://t.me/wsciosipa

## Улучшенный функционал
- 🎯 Перемещаемая плавающая кнопка (перетаскивайте куда удобно)
- 🎨 Красивое современное интерфейс меню с плавными анимациями
- 📢 Кнопка для открытия Telegram канала WSC IOS
- ⚙️ Заглушка для будущих настроек
- ✅ Менее навязчивая кнопка (меньшего размера, приятный цвет)
- 📱 Совместимо с iOS 10.0+

## Компиляция

### Требования
- macOS или Linux с установленным Theos
- Xcode Command Line Tools
- iOS SDK

### Установка Theos (если еще не установлен)
```bash
# На macOS
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# На Linux
sudo apt-get install git make perl curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

### Сборка dylib
```bash
cd TelegramMenuTweak
chmod +x build.sh
./build.sh
```

Или вручную:
```bash
make clean
make package
```

Готовая библиотека будет в: `.theos/obj/debug/TelegramMenuTweak.dylib`

## Инжект в IPA

### Способ 1: Использование insert_dylib

```bash
# 1. Распакуйте IPA
unzip "11.5 (@wscios).ipa" -d Payload

# 2. Инжектируйте dylib
insert_dylib @executable_path/TelegramMenuTweak.dylib "Payload/Soccer Champs.app/Soccer Champs" --all-yes

# 3. Скопируйте dylib в приложение
cp TelegramMenuTweak.dylib "Payload/Soccer Champs.app/"

# 4. Запакуйте обратно
zip -r modified.ipa Payload

# 5. Подпишите с вашим сертификатом
codesign -f -s "Your Certificate Name" "Payload/Soccer Champs.app/TelegramMenuTweak.dylib"
codesign -f -s "Your Certificate Name" "Payload/Soccer Champs.app/Soccer Champs"
```

### Способ 2: Использование optool

```bash
# Инжект
optool install -c load -p @executable_path/TelegramMenuTweak.dylib -t "Payload/Soccer Champs.app/Soccer Champs"

# Скопируйте dylib
cp TelegramMenuTweak.dylib "Payload/Soccer Champs.app/"
```

### Способ 3: Автоматический инжект (скрипт ниже)

## Быстрый инжект (для Windows с WSL)

Создайте файл `inject.sh`:

```bash
#!/bin/bash

IPA_PATH="11.5 (@wscios).ipa"
DYLIB_PATH="TelegramMenuTweak/TelegramMenuTweak.dylib"
APP_NAME="Soccer Champs"
OUTPUT_IPA="11.5_modified.ipa"

# Распаковка
echo "Распаковка IPA..."
unzip -q "$IPA_PATH" -d temp_ipa

# Инжект
echo "Инжект dylib..."
insert_dylib @executable_path/TelegramMenuTweak.dylib "temp_ipa/Payload/$APP_NAME.app/$APP_NAME" --all-yes

# Копирование dylib
echo "Копирование библиотеки..."
cp "$DYLIB_PATH" "temp_ipa/Payload/$APP_NAME.app/"

# Упаковка
echo "Создание модифицированного IPA..."
cd temp_ipa
zip -q -r ../"$OUTPUT_IPA" Payload
cd ..

# Очистка
rm -rf temp_ipa

echo "✓ Готово! Файл: $OUTPUT_IPA"
echo ""
echo "Теперь подпишите IPA с помощью:"
echo "- AltStore / Sideloadly (для не-джейлбрейк устройств)"
echo "- ldid (для джейлбрейк устройств)"
```

## Использование в приложении

После установки модифицированного IPA:

1. Запустите Soccer Champs
2. Появится синяя круглая кнопка с иконкой 💬 (можно перетаскивать пальцем)
3. Нажмите на кнопку - откроется современное меню "WSC IOS" с плавной анимацией
4. Нажмите на кнопку "📢 Telegram Channel"
5. Откроется ваш Telegram канал @wsciosipa
6. Кнопку меню можно перетаскивать в любое место экрана для удобства

## Структура файлов

```
TelegramMenuTweak/
├── Tweak.x                    # Исходный код твика
├── Makefile                   # Makefile для компиляции
├── control                    # Метаданные пакета
├── TelegramMenuTweak.plist   # Фильтр для целевого приложения
├── build.sh                   # Скрипт сборки
└── README.md                  # Этот файл
```

## Технические детали

- **Язык**: Objective-C с Logos (Theos)
- **Зависимости**: mobilesubstrate, UIKit, Foundation
- **Target**: iOS 10.0+, arm64
- **Bundle ID**: com.monkeyibrowstudios.worldsoccerchamps201851
- **Новые функции**:
  - UIPanGestureRecognizer для перетаскивания кнопки
  - Ограничение движения кнопки within screen bounds с отступом
  - Улучшенный UI меню с градиентом, тенью и закругленными углами
  - Плавные анимации появления/исчезновения меню с пружинным эффектом
  - Меньший размер кнопки (56pt вместо 60pt) для меньшего визуального шума
  - Приятный синий цвет вместо оригинального светло-голубого
  - Добавлена белобордовая рамка вокруг кнопки для лучшей видимости
  - Изменена иконка с 📱 на 💬 (более соответствует функции чата)
  - Улучшенная типографика и цветовая схема меню
  - Добален placeholder для настроек (кнопка ⚙️ Settings)

## Возможные проблемы

### dylib не загружается
- Убедитесь, что dylib находится в `Payload/Soccer Champs.app/`
- Проверьте, что инжект прошел успешно: `otool -L "Payload/Soccer Champs.app/Soccer Champs"`

### Кнопка не появляется
- Проверьте логи: подключите устройство к Xcode и смотрите Console
- Убедитесь, что Bundle ID совпадает с вашим приложением

### Приложение крашится
- Пересоберите dylib с флагом `-fobjc-arc`
- Проверьте совместимость iOS версии

## Поддержка

Telegram: @wsciosipa

---

Made with ❤️ for WSC IOS Community