# Telegram Menu Tweak для Soccer Champs

Floating Telegram menu button tweak for Soccer Champs (iOS, Theos).

## Описание

Этот твик добавляет перемещаемую плавающую кнопку меню в приложение Soccer Champs, при нажатии на которую открывается красивое меню с кнопкой для перехода на Telegram канал https://t.me/wsciosipa

## Улучшенный функционал

- 🎯 Перемещаемая плавающая кнопка (перетаскивайте куда удобно)
- 🎨 Красивое современное интерфейс меню с плавными анимациями
- 📢 Кнопка для открытия Telegram канала WSC IOS
- ⚙️ Заглушка для будущих настроек
- ✅ Менее навязчивая кнопка (меньшего размера, приятный цвет)
- 📱 Совместимо с iOS 10.0+

## Быстрая сборка

```bash
make package
```

Готовый `.deb` появится в `packages/`.

## Установка

1. Скопируйте `.deb` на устройство (через SFTP / Filza / `scp`).
2. Установите пакет:
   ```bash
   dpkg -i com.wscios.telegrammenu_1.0_iphoneos-arm.deb
   ```
3. Выполните `respring` или перезагрузите устройство.
4. Запустите Soccer Champs — появится синяя круглая кнопка с иконкой 💬.

После установки:

- Запустите Soccer Champs
- Появится синяя круглая кнопка с иконкой 💬 (можно перетаскивать пальцем)
- Нажмите на кнопку — откроется современное меню «WSC IOS» с плавной анимацией
- Нажмите на кнопку «📢 Telegram Channel»
- Откроется ваш Telegram-канал [@wsciosipa](https://t.me/wsciosipa)
- Кнопку меню можно перетаскивать в любое место экрана

## Поддержка

- Telegram-канал: [@wsciosipa](https://t.me/wsciosipa)
- Issues: [GitHub Issues](https://github.com/zhalol/TelegramMenuTweak/issues)

---

Made with ❤️ for WSC IOS Community
