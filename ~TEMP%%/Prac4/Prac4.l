%{
#include <stdio.h>
#include <string.h>
#include "Prac4.tab.h"

int line = 1;
extern int error_count;

struct Symbol {
    char name[30];
    char type[20];
    int address;
};

struct Symbol table[100]; 
int count = 0;
int addr = 1000;
char dtype[20] = "";

int exists(char *s) {
    for (int i = 0; i < count; i++) {
        if (strcmp(table[i].name, s) == 0) return 1;
    }
    return 0;
}

void insert(char *s) {
    if (strlen(dtype) == 0) return;
    if (exists(s) == 0) {
        strcpy(table[count].name, s);
        strcpy(table[count].type, dtype);
        table[count].address = addr;
        addr += 4;
        count++;
    }
}
%}

letter      [A-Za-z_]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+
float       {digit}+"."{digit}+
invalidid   {digit}+{letter}({letter}|{digit})*

%%

\n          { line++; }
"//".*      { /* ignore single-line comments */ }
"/*"([^*]|\*+[^*/])*\*+"/" { /* ignore multi-line comments */ }
#.*         { /* ignore preprocessor directives like #include */ }

"int"       { strcpy(dtype, "int"); return INT; }
"float"     { strcpy(dtype, "float"); return FLOAT; }
"char"      { strcpy(dtype, "char"); return CHAR; }
"double"    { strcpy(dtype, "double"); return DOUBLE; }

"if"        { dtype[0] = '\0'; return IF; }
"else"      { dtype[0] = '\0'; return ELSE; }
"while"     { dtype[0] = '\0'; return WHILE; }
"for"       { dtype[0] = '\0'; return FOR; }
"return"    { dtype[0] = '\0'; return RETURN; }

"\""[^\"]*"\"" { return STRING; }

{invalidid} { error_count++; }

{id} {
    if (strlen(dtype) != 0) {
        insert(yytext); /* Declaration phase */
    } else if (exists(yytext) == 0) {
        error_count++;

        /* Insert undeclared variable into symbol table to suppress duplicate error logs */
        strcpy(table[count].name, yytext);
        strcpy(table[count].type, "NA");
        table[count].address = addr;
        addr += 4;
        count++;
    }
    return ID;
}

{number}    { return NUMBER; }
{float}     { return FLOAT_VAL; }

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
";"         { dtype[0] = '\0'; return SEMI; }
","         { return COMMA; }

[ \t]+      { /* ignore whitespace */ }
.           { error_count++; }

%%

int yywrap() {
    return 1;
}