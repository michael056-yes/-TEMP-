%{
    #include <stdio.h>
    #include <stdlib.h>

    int yylex(void);
    void yyerror(const char *s);
    extern int line;

    int error_count = 0;
%}

%error-verbose

%token INT FLOAT CHAR DOUBLE IF ELSE WHILE FOR RETURN
%token ID NUMBER FLOAT_VAL STRING
%token LE GE EQ NE LT GT ASSIGN
%token PLUS MINUS MUL DIV INC
%token LSHIFT RSHIFT
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET SEMI COMMA

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%left LSHIFT RSHIFT
%left PLUS MINUS
%left MUL DIV
%right CAST
%left INC

%%

program:
    functions
    ;

functions:
    function
    | functions function
    ;

function:
    type ID LPAREN RPAREN LBRACE statements RBRACE
    | type ID LPAREN params RPAREN LBRACE statements RBRACE
    | type ID LPAREN error RPAREN LBRACE statements RBRACE
      { yyerrok; }
    ;

params:
    param
    | params COMMA param
    | params error COMMA { yyerrok; }
    ;

param:
    type ID
    | type ID LBRACKET RBRACKET
    | type error { yyerrok; }
    ;

statements:
    /* empty */
    | statements statement
    | statements error SEMI
      { yyerrok; }
    ;

statement:
    declaration
    | assignment SEMI
    | expr SEMI
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    ;

declaration:
    type id_list SEMI
    | type error SEMI
      { yyerrok; }
    ;

type:
    INT | FLOAT | CHAR | DOUBLE
    ;

id_list:
    var_decl
    | id_list COMMA var_decl
    | id_list error COMMA
      { yyerrok; }
    ;

var_decl:
    ID
    | ID LBRACKET NUMBER RBRACKET
    | ID ASSIGN expr
    ;

assignment:
    ID ASSIGN expr
    | ID LBRACKET expr RBRACKET ASSIGN expr
    ;

if_statement:
    IF LPAREN condition RPAREN LBRACE statements RBRACE %prec LOWER_THAN_ELSE
    | IF LPAREN condition RPAREN LBRACE statements RBRACE ELSE LBRACE statements RBRACE
    | IF LPAREN condition RPAREN statement %prec LOWER_THAN_ELSE
    | IF LPAREN condition RPAREN statement ELSE statement
    | IF error LBRACE statements RBRACE %prec LOWER_THAN_ELSE
      { yyerrok; }
    ;

while_statement:
    WHILE LPAREN condition RPAREN LBRACE statements RBRACE
    | WHILE LPAREN condition RPAREN statement
    | WHILE error LBRACE statements RBRACE
      { yyerrok; }
    ;

for_statement:
    FOR LPAREN assignment SEMI condition SEMI expr RPAREN LBRACE statements RBRACE
    | FOR LPAREN declaration condition SEMI expr RPAREN LBRACE statements RBRACE
    | FOR LPAREN error RPAREN LBRACE statements RBRACE
      { yyerrok; }
    ;

return_statement:
    RETURN expr SEMI
    | RETURN SEMI
    | RETURN error SEMI
      { yyerrok; }
    ;

condition:
    expr rel_op expr
    | expr
    ;

rel_op:
    LT | GT | LE | GE | EQ | NE
    ;

expr:
    expr PLUS expr
    | expr MINUS expr
    | expr MUL expr
    | expr DIV expr
    | expr LSHIFT expr
    | expr RSHIFT expr
    | LPAREN type RPAREN expr %prec CAST
    | LPAREN expr RPAREN
    | expr INC
    | ID
    | ID LBRACKET expr RBRACKET
    | NUMBER
    | FLOAT_VAL
    | STRING
    ;

%%

void yyerror(const char *s) {
    printf("Syntax Error at line %d: %s\n", line, s);
    error_count++;
}

int main(void) {
    if (yyparse() == 0 && error_count == 0) {
        printf("done without error\n");
    } else {
        printf("Parsing completed with %d error(s)\n", error_count);
    }
    return 0;
}
