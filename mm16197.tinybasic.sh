#!/bin/sh
#   ./mm16197.tinybasic.sh              builds everything
#   ./mm16197.tinybasic.sh sample.bas   builds and checks sample.bas

if [ ! -f ./trans ]; then
   ./mm16197.trans.sh
fi

./trans < mm16197.tinybasic.in > mm16197.tinybasic.y
if [ $? -ne 0 ]; then
   echo "translator failed"
   exit 1
fi

bison -d mm16197.tinybasic.y
flex -o tinybasic.lex.c mm16197.tinybasic.l
g++ -o tinybasic tinybasic.lex.c mm16197.tinybasic.tab.c

if [ "$1" != "" ]; then
   ./tinybasic < "$1"
fi
