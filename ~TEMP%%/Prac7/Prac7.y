%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Labels {
    int start, yes, no, end;
} Labels;

int tc = 0, lc = 0;

char *newTemp(void) {
    char b[32];
    sprintf(b, "t%d", ++tc);
    return strdup(b);
}

int newLabel(void) {
    return ++lc;
}

char *makeOp(char *a, const char *o, char *b) {
    char *t = newTemp();
    printf("%s = %s %s %s\n", t, a, o, b);
    free(a);
    free(b);
    return t;
}

char *makeCond(char *a, const char *o, char *b) {
    char *s = malloc(strlen(a) + strlen(o) + strlen(b) + 4);
    sprintf(s, "%s %s %s", a, o, b);
    free(a);
    free(b);
    return s;
}

int yylex(void);
void yyerror(const char *s);
%}

%union {
    char *str;
    struct Labels *lab;
}

%token IF ELSE WHILE INT FLOAT
%token <str> ID NUM
%token EQ NE LE GE

%type <str> expr cond
%type <lab> ifhead while_start whilehead

%nonassoc IFX
%nonassoc ELSE
%left '+' '-'
%left '*' '/'

%%

program:
    stmts
    ;

stmts:
    stmts stmt
    | stmt
    ;

stmt:
    INT ID ';'
    {
        free($2);
    }
    | FLOAT ID ';'
    {
        free($2);
    }
    | ID '=' expr ';'
    {
        printf("%s = %s\n", $1, $3);
        free($1);
        free($3);
    }
    | '{' stmts '}'
    | ifhead stmt %prec IFX
    {
        printf("L%d:\n", $1->no);
        free($1);
    }
    | ifhead stmt ELSE
    {
        $1->end = newLabel();
        printf("goto L%d\n", $1->end);
        printf("L%d:\n", $1->no);
    }
    stmt
    {
        printf("L%d:\n", $1->end);
        free($1);
    }
    | whilehead stmt
    {
        printf("goto L%d\n", $1->start);
        printf("L%d:\n", $1->no);
        free($1);
    }
    ;

ifhead:
    IF '(' cond ')'
    {
        $$ = malloc(sizeof(Labels));
        $$->yes = newLabel();
        $$->no = newLabel();
        $$->end = 0;

        printf("if %s goto L%d\n", $3, $$->yes);
        printf("goto L%d\n", $$->no);
        printf("L%d:\n", $$->yes);

        free($3);
    }
    ;

while_start:
    WHILE
    {
        $$ = malloc(sizeof(Labels));
        $$->start = newLabel();
        printf("L%d:\n", $$->start);
    }
    ;

whilehead:
    while_start '(' cond ')'
    {
        $$ = $1;
        $$->yes = newLabel();
        $$->no = newLabel();

        printf("if %s goto L%d\n", $3, $$->yes);
        printf("goto L%d\n", $$->no);
        printf("L%d:\n", $$->yes);

        free($3);
    }
    ;

cond:
    expr '<' expr
    {
        $$ = makeCond($1, "<", $3);
    }
    | expr '>' expr
    {
        $$ = makeCond($1, ">", $3);
    }
    | expr EQ expr
    {
        $$ = makeCond($1, "==", $3);
    }
    | expr NE expr
    {
        $$ = makeCond($1, "!=", $3);
    }
    | expr LE expr
    {
        $$ = makeCond($1, "<=", $3);
    }
    | expr GE expr
    {
        $$ = makeCond($1, ">=", $3);
    }
    ;

expr:
    ID
    {
        $$ = $1;
    }
    | NUM
    {
        $$ = $1;
    }
    | expr '+' expr
    {
        $$ = makeOp($1, "+", $3);
    }
    | expr '-' expr
    {
        $$ = makeOp($1, "-", $3);
    }
    | expr '*' expr
    {
        $$ = makeOp($1, "*", $3);
    }
    | expr '/' expr
    {
        $$ = makeOp($1, "/", $3);
    }
    | '(' expr ')'
    {
        $$ = $2;
    }
    ;

%%

void yyerror(const char *s) {
    (void)s;
}

int main(void) {
    yyparse();
    return 0;
}
