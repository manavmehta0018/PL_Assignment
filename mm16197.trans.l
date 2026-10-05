%{
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

using namespace std;

#include "mm16197.trans.tab.h"

extern string sec1;
extern map<string, string> symType;
extern set<string> usedNames;

int inDecl = 0;
string curTag = "";
%}

%option noyywrap
%option yylineno

%x RULES
%x SEC3

%%

"%{"    {
          sec1 += yytext;
          int c;
          int prev = 0;
          while (1)
          {
             c = yyinput();
             if (c == 0 || c == EOF)
             {
                cerr << "syntax error: %{ is never closed" << endl;
                exit(1);
             }
             sec1 += (char)c;
             if (prev == '%' && c == '}')
                break;
             prev = c;
          }
        }

"/*"    {
          sec1 += yytext;
          int c;
          int prev = 0;
          while ((c = yyinput()) != 0 && c != EOF)
          {
             sec1 += (char)c;
             if (prev == '*' && c == '/')
                break;
             prev = c;
          }
        }

"%token"|"%type"|"%nterm"|"%left"|"%right"|"%nonassoc"|"%precedence"   {
          sec1 += yytext;
          inDecl = 1;
          curTag = "";
        }

"%"[a-z_\-]+   { sec1 += yytext; inDecl = 0; }

"<"[^<>\n]*">"   {
          sec1 += yytext;
          if (inDecl)
             curTag = yytext;
        }

[a-zA-Z_][a-zA-Z0-9_.\-]*|\'(\\.|[^\\'\n])+\'|\"(\\.|[^\\"\n])*\"   {
          sec1 += yytext;
          if (inDecl && curTag != "")
             symType[yytext] = curTag;
        }

^"%%"   {
          BEGIN(RULES);
          return SECTION;
        }

.|\n    { sec1 += yytext; }



<RULES>"/*"    {
                  int c;
                  int prev = 0;
                  while (1)
                  {
                    c = yyinput();
                    if (c == 0 || c == EOF)
                    {
                       cerr << "syntax error: comment never closed" << endl;
                       exit(1);
                    }
                    if (prev == '*' && c == '/')
                       break;
                    prev = c;
                  }
               }

<RULES>"//".*   { }

<RULES>"%%"     {
                  BEGIN(SEC3);
                  return SECTION;
                }

<RULES>"||"     { return GROUP_OR; }
<RULES>"|"      { return RULE_OR; }
<RULES>":"      { return REWRITES; }
<RULES>";"      { return SEMI; }

<RULES>"<"      { return REP_ZERO_LEFT; }
<RULES>">"      { return REP_ZERO_RIGHT; }
<RULES>"["      { return OPTION_LEFT; }
<RULES>"]"      { return OPTION_RIGHT; }
<RULES>"("      { return GROUPING_LEFT; }
<RULES>")"      { return GROUPING_RIGHT; }
<RULES>"+"      { return REP_ONE; }
<RULES>"*"      { return REP_ZERO; }

<RULES>"%"[a-zA-Z]+    { yylval.str = new string(yytext); return TERM_OR_NONTERM; }

<RULES>[a-zA-Z_.][a-zA-Z0-9_.\-]*   { yylval.str = new string(yytext); return TERM_OR_NONTERM; }

<RULES>\'(\\.|[^\\'\n])+\'   { yylval.str = new string(yytext); return TERM_OR_NONTERM; }

<RULES>\"(\\.|[^\\"\n])*\"   { yylval.str = new string(yytext); return TERM_OR_NONTERM; }

<RULES>"{"      {
                  string code = "{";
                  int depth = 1;
                  int c;
                  while (depth > 0)
                  {
                     c = yyinput();
                     if (c == 0 || c == EOF)
                     {
                        cerr << "syntax error: action never closed, line " << yylineno << endl;
                        exit(1);
                     }
                     if (c == '{') depth++;
                     if (c == '}') depth--;
                     code += (char)c;
                  }
                  yylval.str = new string(code);
                  return ACTION;
                }

<RULES>[ \t\r\n]+   { }

<RULES>.        {
                  cerr << "syntax error: unexpected " << yytext << " on line " << yylineno << endl;
                  exit(1);
                }



<SEC3>.|\n      { cout << yytext; }

%%

void readInput()
{
   string all = "";
   int c;
   while ((c = getchar()) != EOF)
      all += (char)c;

   string w1 = "";
   string w2 = "";
   for (int i = 0; i <= all.size(); i++)
   {
      char ch = ' ';
      if (i < all.size())
         ch = all[i];

      if (isalnum(ch) || ch == '_' || ch == '.' || ch == '-')
         w1 += ch;
      else
      {
         if (w1 != "") usedNames.insert(w1);
         w1 = "";
      }

      if (isalnum(ch) || ch == '_')
         w2 += ch;
      else
      {
         if (w2 != "") usedNames.insert(w2);
         w2 = "";
      }
   }

   yy_scan_string(all.c_str());
}
