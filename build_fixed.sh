#!/bin/bash
export THEOS=/root/theos
export PATH=/root/theos/bin:$PATH
echo $THEOS
ls $THEOS/vendor/include/
cd /mnt/c/Users/Жалол/Desktop/WSC/TelegramMenuTweak_build
make clean && make