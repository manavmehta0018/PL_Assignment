%{
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <stdio.h>
#include <stdlib.h>

using namespace std;

int yylex();
void readInput();
extern int yylineno;

int yyerror(const char *p)
{
   cerr << "syntax error on line " << yylineno << endl;
   exit(1);
}

string sec1 = "";
string output = "";
string extraRules = "";
string typeLines = "";
string curLHS = "";
int cnt = 0;

map<string, string> symType;
set<string> usedNames;


string newName(string kind)
{
   string name;
   do
   {
      cnt++;
      name = curLHS + "_" + kind + to_string(cnt);
   } while (usedNames.count(name) > 0);

   usedNames.insert(name);
   return name;
}

string altText(string a)
{
   if (a == "")
      return "/* empty */";
   return a;
}

string firstWord(string alt, string self)
{
   string w = "";
   for (int i = 0; i <= alt.size(); i++)
   {
      if (i == alt.size() || alt[i] == ' ')
      {
         if (w != "" && w != self && w[0] != '%')
            return w;
         w = "";
      }
      else
         w += alt[i];
   }
   return "";
}

string findType(string name, vector<string> alts)
{
   string t = "";
   for (int i = 0; i < alts.size(); i++)
   {
      string f = firstWord(alts[i], name);
      if (f == "")
         continue;
      if (symType.count(f) == 0)
         return "";
      if (t == "")
         t = symType[f];
      else if (t != symType[f])
         return "";
   }
   return t;
}

void addRule(string name, vector<string> alts)
{
   string t = findType(name, alts);
   if (t != "")
   {
      symType[name] = t;
      typeLines += "%type " + t + " " + name + "\n";
   }

   string r = name + " : ";
   for (int i = 0; i < alts.size(); i++)
   {
      if (i > 0)
         r = r + "\n    | ";
      r = r + altText(alts[i]);
      if (alts[i] == "" && t != "")
         r = r + " { }";
   }
   r = r + "\n    ;\n\n";
   extraRules += r;
}

string doGroup(vector<string>* alts)
{
   if (alts->size() == 1)
      return (*alts)[0];

   string name = newName("grp");
   addRule(name, *alts);
   return name;
}

string doOption(vector<string>* alts)
{
   vector<string> v;
   v.push_back("");
   for (int i = 0; i < alts->size(); i++)
   {
      if ((*alts)[i] != "")
         v.push_back((*alts)[i]);
   }
   if (v.size() == 1)
      return "";

   string name = newName("opt");
   addRule(name, v);
   return name;
}

string doStar(string a)
{
   if (a == "")
      return "";

   string name = newName("star");
   vector<string> v;
   v.push_back("");
   v.push_back(name + " " + a);
   addRule(name, v);
   return name;
}

string doPlus(string a)
{
   if (a == "")
      return "";

   string name = newName("plus");
   vector<string> v;
   v.push_back(a);
   v.push_back(name + " " + a);
   addRule(name, v);
   return name;
}

void printAll()
{
   cout << sec1;
   if (typeLines != "")
   {
      if (sec1 != "" && sec1[sec1.size() - 1] != '\n')
         cout << "\n";
      cout << typeLines;
   }
   cout << "%%\n\n" << output;
}

%}

%union {
   std::string* str;
   std::vector<std::string>* list;
};

%start prog

%token <str> TERM_OR_NONTERM ACTION
%token SECTION REWRITES SEMI RULE_OR GROUP_OR
%token REP_ZERO_LEFT REP_ZERO_RIGHT
%token OPTION_LEFT OPTION_RIGHT
%token GROUPING_LEFT GROUPING_RIGHT
%token REP_ONE REP_ZERO

%type <str> seq item
%type <list> alts galts

%%

prog : SECTION rules SECTION     { printAll(); cout << "%%"; }
     | SECTION rules             { printAll(); }
     ;

rules : rule
      | rules rule
      ;

rule : TERM_OR_NONTERM { curLHS = *$1; extraRules = ""; } REWRITES alts SEMI
        {
           string r = *$1 + " : " + altText((*$4)[0]);
           for (int i = 1; i < $4->size(); i++)
              r = r + "\n    | " + altText((*$4)[i]);
           r = r + "\n    ;\n\n";

           output += r;
           output += extraRules;
           extraRules = "";
        }
     ;

alts : seq                  { $$ = new vector<string>(); $$->push_back(*$1); }
     | alts RULE_OR seq     { $$ = $1; $$->push_back(*$3); }
     ;

galts : seq                 { $$ = new vector<string>(); $$->push_back(*$1); }
      | galts GROUP_OR seq  { $$ = $1; $$->push_back(*$3); }
      ;

seq : %empty                { $$ = new string(""); }
    | seq item
       {
          if (*$2 == "")
             $$ = $1;
          else if (*$1 == "")
             $$ = $2;
          else
             $$ = new string(*$1 + " " + *$2);
       }
    ;

item : TERM_OR_NONTERM                          { $$ = $1; }
     | ACTION                                   { $$ = $1; }
     | GROUPING_LEFT galts GROUPING_RIGHT       { $$ = new string(doGroup($2)); }
     | OPTION_LEFT galts OPTION_RIGHT           { $$ = new string(doOption($2)); }
     | REP_ZERO_LEFT galts REP_ZERO_RIGHT       { $$ = new string(doStar(doGroup($2))); }
     | item REP_ZERO                            { $$ = new string(doStar(*$1)); }
     | item REP_ONE                             { $$ = new string(doPlus(*$1)); }
     ;

%%

int main()
{
    readInput();
    yyparse();
    return 0;
}
