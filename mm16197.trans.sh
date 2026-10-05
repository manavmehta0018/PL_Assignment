
bison -d mm16197.trans.y
flex mm16197.trans.l
g++ -o trans lex.yy.c mm16197.trans.tab.c
