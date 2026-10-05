%{
#include <iostream>
#include <stdlib.h>
using namespace std;

#include "mm16197.tinybasic.tab.h"

int lastCR = 1;
int gotEOF = 0;

int tok(int t)
{
   lastCR = 0;
   return t;
}
%}

%option noyywrap
%option yylineno

%%

"PRINT"     { return tok(PRINT); }
"IF"        { return tok(IF); }
"THEN"      { return tok(THEN); }
"GOTO"      { return tok(GOTO); }
"INPUT"     { return tok(INPUT); }
"LET"       { return tok(LET); }
"GOSUB"     { return tok(GOSUB); }
"RETURN"    { return tok(RETURN); }
"CLEAR"     { return tok(CLEAR); }
"LIST"      { return tok(LIST); }
"RUN"       { return tok(RUN); }
"END"       { return tok(END); }

"<>"|"><"|"<="|">="|"<"|">"   { return tok(RELOP); }
"="         { return tok(EQUALS); }

"+"|"-"     { return tok(PLUMIN); }
"*"|"/"     { return tok(MULDIV); }

","         { return tok(COMMA); }
"("         { return tok(LPAREN); }
")"         { return tok(RPAREN); }

[A-Z]       { return tok(VAR); }

[0-9][ \t]+/[0-9]   { cerr << "syntax error on line " << yylineno << endl; exit(1); }
[0-9]       { return tok(DIGIT); }

\"[^"\n]*\"   { return tok(STRING); }

\n([ \t\r]*\n)*   {
                    if (lastCR == 0)
                    {
                       lastCR = 1;
                       return CR;
                    }
                  }

[ \t\r]+    { }

<<EOF>>     {
              if (lastCR == 0 && gotEOF == 0)
              {
                 gotEOF = 1;
                 lastCR = 1;
                 return CR;
              }
              return 0;
            }

.           { cerr << "syntax error: bad character " << yytext << " on line " << yylineno << endl; exit(1); }

%%
