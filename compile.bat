@echo off
echo ====================================
echo   Компиляция TelegramMenuTweak
echo ====================================
echo.

echo Проверка WSL...
wsl --status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WSL не установлен!
    echo.
    echo Установите WSL командой:
    echo   wsl --install
    echo.
    echo После установки перезагрузите компьютер и запустите этот скрипт снова.
    pause
    exit /b 1
)

echo WSL найден. Запуск компиляции...
echo.

wsl bash -c "cd '/mnt/c/Users/Жалол/Desktop/WSC/11.5/TelegramMenuTweak' && if [ ! -d '$THEOS' ]; then echo 'Установка Theos...'; bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)\"; fi && echo 'Компиляция...' && make clean && make && if [ -f '.theos/obj/debug/TelegramMenuTweak.dylib' ]; then cp .theos/obj/debug/TelegramMenuTweak.dylib ./TelegramMenuTweak.dylib && echo 'Готово! Файл: TelegramMenuTweak.dylib'; else echo 'Ошибка компиляции'; fi"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ====================================
    echo   Компиляция завершена!
    echo ====================================
    echo.
    echo Файл dylib находится здесь:
    echo C:\Users\Жалол\Desktop\WSC\11.5\TelegramMenuTweak\TelegramMenuTweak.dylib
    echo.
) else (
    echo.
    echo Ошибка компиляции. Проверьте логи выше.
)

pause
