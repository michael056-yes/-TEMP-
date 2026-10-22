%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "Prac6.tab.h"

int line = 1;
%}

%%

\n          { line++; }
"//".*      { /* ignore comments */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* ignore multi-line comments */ }
#.*         { /* ignore preprocessor directives */ }

"int"       { return INT; }
"float"     { return FLOAT; }
"char"      { return CHAR; }
"double"    { return DOUBLE; }

"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"return"    { return RETURN; }

"\""[^\"]*"\"" { return STRING; }

[0-9]+[A-Za-z_][A-Za-z0-9_]* { 
    printf("Lexical Error: Invalid Identifier '%s' at line %d\n", yytext, line); 
}

[A-Za-z_][A-Za-z0-9_]* {
    yylval.sval = strdup(yytext);
    return ID;
}

[0-9]+              { return NUMBER; }
[0-9]+"."[0-9]+     { return FLOAT_VAL; }

"++"        { return INC; }
"<<"        { return LSHIFT; }
">>"        { return RSHIFT; }
"<="        { return LE; }
">="        { return GE; }
"=="        { return EQ; }
"!="        { return NE; }
"<"         { return LT; }
">"         { return GT; }
"="         { return ASSIGN; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"["         { return LBRACKET; }
"]"         { return RBRACKET; }
";"         { return SEMI; }
","         { return COMMA; }

[ \t]+      { /* ignore whitespace */ }
.           { printf("Lexical Error: Invalid Character '%s' at line %d\n", yytext, line); }

%%

int yywrap() {
    return 1;
}