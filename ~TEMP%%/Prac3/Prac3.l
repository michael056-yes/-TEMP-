%{
#include <stdio.h>
#include <string.h>

int line = 1;

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
    int i;
    for (i = 0; i < count; i++) {
        if (strcmp(table[i].name, s) == 0) {
            return 1;
        }
    }
    return 0;
}

void insert(char *s) {
    if (strlen(dtype) == 0) {
        return;
    }

    if (exists(s) == 0) {
        strcpy(table[count].name, s);
        strcpy(table[count].type, dtype);
        table[count].address = addr;
        addr = addr + 4;
        count++;
    }
}
%}

%x COMMENT

letter      [A-Za-z_]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+
float       {digit}+"."{digit}+
invalidid   {digit}+{letter}({letter}|{digit})*

%%

\n { 
    line++; 
}

"//".* { }

"/*"([^*]|\*+[^*/])*\*+"/" { }

#.* { }
 
"int" { 
    strcpy(dtype, "int"); 
    printf("Keyword : INT\n"); 
}

"float" { 
    strcpy(dtype, "float"); 
    printf("Keyword : FLOAT\n"); 
}

"char" { 
    strcpy(dtype, "char"); 
    printf("Keyword : CHAR\n"); 
}

"double" { 
    strcpy(dtype, "double"); 
    printf("Keyword : DOUBLE\n"); 
}

"if" { printf("Keyword : IF\n"); }
"while" { printf("Keyword : WHILE\n"); }
"else" { printf("Keyword : ELSE\n"); }
"return" { printf("Keyword : RETURN\n"); }

{invalidid} {
    printf("Invalid Identifier : %s at line %d\n", yytext, line);
}

{id} {
    char buf[64];
    int bi = 0;
    int c;

    c = input();
    while (c == ' ' || c == '\t') {
        buf[bi++] = c;
        c = input();
    }

    if (c == '(') {
        printf("Function Name : %s\n", yytext);
        dtype[0] = '\0';
    }
    else if (strlen(dtype) != 0) {
        printf("Identifier (declared) : %s\n", yytext);
        insert(yytext);
    }
    else if (exists(yytext) == 1) {
        printf("Identifier (used) : %s\n", yytext);
    }
    else {
        printf("Error : Undeclared variable : %s at line %d\n", yytext, line);
        strcpy(table[count].name, yytext);
        strcpy(table[count].type, "NA");
        table[count].address = addr;
        addr = addr + 4;
        count++;
    }

    unput(c);
    while (bi > 0) {
        bi--;
        unput(buf[bi]);
    }
}

{number} { 
    printf("Number : %s\n", yytext); 
}

{float} {
    printf("Float: %s\n", yytext);
}

"+" { printf("Arithmetic Operator : +\n"); }
"-" { printf("Arithmetic Operator : -\n"); }
"*" { printf("Arithmetic Operator : *\n"); }
"/" { printf("Arithmetic Operator : /\n"); }
"=" { printf("Assignment Operator : =\n"); }

"<=" { printf("less than or equal to.\n"); }
">=" { printf("greater than or equal to.\n"); }
"<"  { printf("less than.\n"); }
">"  { printf("greater than.\n"); }

"(" { printf("Left Parenthesis\n"); }
")" { printf("Right Parenthesis\n"); }
"{" { printf("Left Curly Brace\n"); }
"}" { printf("Right Curly Brace\n"); }
"[" { printf("Right Square Brace\n"); }
"]" { printf("Left Square Brace\n"); }

";" {
    printf("Semicolon\n");
    dtype[0] = '\0';
}

"," { 
    printf("Comma\n"); 
}

[ \t]+ { }

. { 
    printf("Invalid Character : %s at line %d\n", yytext, line); 
}

%%

int yywrap() {
    return 1;
}

int main() {
    int i;
    
    yylex();

    printf("\n");

    for (i = 0; i < count; i++) {
        printf("%-15s %-10s %-10d\n", table[i].name, table[i].type, table[i].address);
    }

    return 0; 
}