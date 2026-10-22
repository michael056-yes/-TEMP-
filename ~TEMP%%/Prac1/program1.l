%{
#include <stdio.h>
%}

%option noyywrap

%%
[0-9]+      { printf("%s is NUM\n", yytext); }
[ \t\n]+  { }
.+           { printf("%s is invalid token\n", yytext); }
%%
int main()
{
	yylex();
	return 0;
}