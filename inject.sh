#!/bin/bash

IPA_PATH="./11.5 (@wscios).ipa"
DYLIB_NAME="botcczz.dylib"
BUNDLE_NAME="botcczz.bundle"
APP_NAME="Soccer Champs"
OUTPUT_IPA="./11.5_modified.ipa"
BUNDLE_ID="com.monkeyibrowstudios.worldsoccerchamps201851"

echo "========================================="
echo "  Soccer Champs - Telegram Menu Injector"
echo "========================================="
echo ""

# Проверка наличия IPA
if [ ! -f "$IPA_PATH" ]; then
    echo "✗ Ошибка: IPA файл не найден: $IPA_PATH"
    exit 1
fi

# Проверка наличия dylib
if [ ! -f "$DYLIB_NAME" ]; then
    echo "✗ Ошибка: dylib не найден: $DYLIB_NAME"
    echo "  Сначала соберите проект: ./build.sh"
    exit 1
fi

# Проверка инструмента для инжекта
# Используем наш Python-скрипт (не требует Xcode), fallback на insert_dylib если есть
if [ -f "inject_dylib.py" ]; then
    INJECT_TOOL="python3 inject_dylib.py --weak"
    echo "→ Используем кастомный Python-инжектор (inject_dylib.py)"
elif command -v insert_dylib &> /dev/null; then
    INJECT_TOOL="insert_dylib --weak --all-yes"
    echo "→ Используем insert_dylib"
else
    echo "✗ Не найден инструмент для инжекта dylib"
    echo "  Нужен либо inject_dylib.py (есть в проекте), либо insert_dylib"
    exit 1
fi

# Создание временной директории
echo "→ Создание временной директории..."
rm -rf temp_inject
mkdir -p temp_inject

# Распаковка IPA
echo "→ Распаковка IPA..."
unzip -q "$IPA_PATH" -d temp_inject

# Путь к исполняемому файлу
EXEC_PATH="temp_inject/Payload/$APP_NAME.app/$APP_NAME"

if [ ! -f "$EXEC_PATH" ]; then
    echo "✗ Ошибка: Исполняемый файл не найден: $EXEC_PATH"
    rm -rf temp_inject
    exit 1
fi

# Резервное копирование оригинального бинарника
echo "→ Создание резервной копии..."
cp "$EXEC_PATH" "${EXEC_PATH}.backup"

# Инжект dylib
echo "→ Инжект dylib в исполняемый файл..."
$INJECT_TOOL "@executable_path/$DYLIB_NAME" "$EXEC_PATH"

if [ $? -ne 0 ]; then
    echo "✗ Ошибка инжекта!"
    rm -rf temp_inject
    exit 1
fi

# Копирование dylib в приложение
echo "→ Копирование $DYLIB_NAME..."
cp "$DYLIB_NAME" "temp_inject/Payload/$APP_NAME.app/"

# Копирование bundle с иконкой (если есть)
if [ -d "$BUNDLE_NAME" ]; then
    echo "→ Копирование $BUNDLE_NAME..."
    cp -R "$BUNDLE_NAME" "temp_inject/Payload/$APP_NAME.app/"
else
    echo "⚠ $BUNDLE_NAME не найден — будет использована иконка по умолчанию"
fi

# Проверка инжекта
echo "→ Проверка инжекта..."
if command -v otool &> /dev/null; then
    otool -L "$EXEC_PATH" | grep "$DYLIB_NAME" > /dev/null
    INJECT_OK=$?
elif [ -f "verify_macho.py" ]; then
    python3 verify_macho.py "$EXEC_PATH" | grep -q "$DYLIB_NAME"
    INJECT_OK=$?
else
    INJECT_OK=0  # наивное предположение что прошло
fi

if [ $INJECT_OK -eq 0 ]; then
    echo "✓ Инжект успешно выполнен!"
else
    echo "✗ Ошибка: dylib не была инжектирована"
    rm -rf temp_inject
    exit 1
fi

# Упаковка обратно в IPA
echo "→ Создание модифицированного IPA..."
# Use absolute path so cd into temp_inject doesn't break the output location
ABS_OUTPUT="$(cd "$(dirname "$OUTPUT_IPA")" && pwd)/$(basename "$OUTPUT_IPA")"
cd temp_inject
zip -q -r "$ABS_OUTPUT" Payload
cd ..

# Очистка
echo "→ Очистка временных файлов..."
rm -rf temp_inject

# Проверка результата
if [ -f "$OUTPUT_IPA" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_IPA" | cut -f1)
    echo ""
    echo "========================================="
    echo "✓ Готово!"
    echo "========================================="
    echo "  Файл: $OUTPUT_IPA"
    echo "  Размер: $FILE_SIZE"
    echo ""
    echo "Следующие шаги:"
    echo "1. Подпишите IPA одним из способов:"
    echo "   • AltStore (для не-джейлбрейк)"
    echo "   • Sideloadly (для не-джейлбрейк)"
    echo "   • ldid (для джейлбрейк)"
    echo ""
    echo "2. Установите на устройство"
    echo ""
    echo "3. При запуске приложения появится кнопка 📱"
    echo "   в правом верхнем углу для открытия меню"
    echo ""
else
    echo "✗ Ошибка создания IPA"
    exit 1
fi
