%{
    #include<stdio.h>
%}

%%
"if"|"else" {
    printf("%s, a conditional statement\n", yytext);
}

"switch"|"case" {
    printf("%s, a switch case statement\n", yytext);
}

"for"|"while"|"do" {
    printf("%s, a loop statement\n", yytext);
}

"<"|">"|"<="|">="|"==" {
    printf("%s, a comparator\n", yytext);
}

"("|")"|"()" {
    printf("%s, a bracket\n", yytext);
}

"["|"]"|"[]" {
    printf("%s, a sq. bracket\n", yytext);
}

"{"|"}"|"{}" {
    printf("%s, a curly bracket\n", yytext);
}

[0-9]+ {
    printf("%s is a number\n", yytext);
}

[a-zA-Z_][a-zA-Z0-9_]* {
    printf("%s is a generic string\n", yytext);
}

[0-9]+[a-zA-Z_][a-zA-Z0-9_]* {
    printf("%s is an invalid variable\n", yytext);
}

"/*"([^*]|\*+[^*/])*\*+"/" {
    printf("multiline comment found\n");
}

"//".* {
    printf("single line comment found\n");
}

[ \t\n]+ {}

. { }
%%

int yywrap(){
    return 1;
}

int main() {
    printf("Lex started \n");
    yylex();
    return 0;
}


//invalid var
//multiline or non-terminating comment found or not