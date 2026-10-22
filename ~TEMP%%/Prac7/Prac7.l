
%{
#include "Prac7.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%option noyywrap

%%

"if"                    { return IF; }
"else"                  { return ELSE; }
"while"                 { return WHILE; }
"int"                   { return INT; }
"float"                 { return FLOAT; }

"=="                    { return EQ; }
"!="                    { return NE; }
"<="                    { return LE; }
">="                    { return GE; }

[0-9]+\.[0-9]+          { yylval.str = strdup(yytext); return NUM; }
[0-9]+                  { yylval.str = strdup(yytext); return NUM; }

[a-zA-Z_][a-zA-Z0-9_]*  {
                            yylval.str = strdup(yytext);
                            return ID;
                        }

[ \t\r\n]+              ;

"="                     { return '='; }
"<"                     { return '<'; }
">"                     { return '>'; }
"+"                     { return '+'; }
"-"                     { return '-'; }
"*"                     { return '*'; }
"/"                     { return '/'; }

"("                     { return '('; }
")"                     { return ')'; }
"{"                     { return '{'; }
"}"                     { return '}'; }
";"                     { return ';'; }

.                       { return yytext[0]; }

%%
