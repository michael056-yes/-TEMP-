%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    int yylex(void);
    void yyerror(const char *s);

    extern int line;
    int error_count = 0;

    struct Symbol {
        char name[30];
        char type[20];
        int address;
        int is_initialized;
    };

    struct Symbol table[100];
    int count = 0;
    int addr = 1000;

    char current_dtype[20] = "";

    int lookup(const char *name) {
        for (int i = 0; i < count; i++) {
            if (strcmp(table[i].name, name) == 0) {
                return i;
            }
        }
        return -1;
    }

    void insert_symbol(const char *name, const char *type) {
        int idx = lookup(name);
        if (idx != -1) {
            printf("Semantic Error: Redeclaration of variable '%s' at line %d\n", name, line);
            error_count++;
            return;
        }
        strcpy(table[count].name, name);
        strcpy(table[count].type, type);
        table[count].address = addr;
        table[count].is_initialized = 0; 
        addr += 4;
        count++;
    }

    void mark_initialized(const char *name) {
        int idx = lookup(name);
        if (idx != -1) {
            table[idx].is_initialized = 1;
        }
    }

    char* check_symbol_usage_and_get_type(const char *name, int check_init) {
        int idx = lookup(name);
        if (idx == -1) {
            printf("Semantic Error: Undeclared variable '%s' at line %d\n", name, line);
            error_count++;

            strcpy(table[count].name, name);
            strcpy(table[count].type, "NA");
            table[count].address = addr;
            table[count].is_initialized = 1;
            addr += 4;
            count++;
            return "NA";
        }
        
        if (check_init && table[idx].is_initialized == 0) {
            printf("Semantic Error: Uninitialized variable '%s' used at line %d\n", name, line);
            error_count++;
        }
        return table[idx].type;
    }

    char* check_type(char* t1, char* t2) {
        if (!t1 || !t2) return "error";
        if (strcmp(t1, "NA") == 0 || strcmp(t2, "NA") == 0 || strcmp(t1, "error") == 0 || strcmp(t2, "error") == 0) {
            return "error";
        }
        if (strcmp(t1, t2) != 0) {
            if ((strcmp(t1, "int") == 0 && (strcmp(t2, "float") == 0 || strcmp(t2, "double") == 0)) ||
                (strcmp(t2, "int") == 0 && (strcmp(t1, "float") == 0 || strcmp(t1, "double") == 0))) {
                return "float"; 
            }
            printf("Semantic Error: Datatype mismatch ('%s' and '%s') at line %d\n", t1, t2, line);
            error_count++;
            return "error";
        }
        return t1;
    }

    void print_symbol_table() {
        printf("%-15s %-10s %-10s %-15s\n", "Identifier", "Type", "Address", "Initialized");
        for (int i = 0; i < count; i++) {
            printf("%-15s %-10s %-10d %-15d\n", table[i].name, table[i].type, table[i].address, table[i].is_initialized);
        }
    }
%}

%union {
    char *sval;
}

%token <sval> ID
%token INT FLOAT CHAR DOUBLE IF ELSE WHILE FOR RETURN
%token NUMBER FLOAT_VAL STRING
%token LE GE EQ NE LT GT ASSIGN
%token PLUS MINUS MUL DIV INC
%token LSHIFT RSHIFT
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET SEMI COMMA

%type <sval> expr

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
    type ID LPAREN RPAREN LBRACE statements RBRACE {
        insert_symbol($2, "function");
        mark_initialized($2);
        free($2);
    }
    | type ID LPAREN params RPAREN LBRACE statements RBRACE {
        insert_symbol($2, "function");
        mark_initialized($2);
        free($2);
    }
    | error RBRACE { yyerrok; }
    ;

params:
    param
    | params COMMA param
    ;

param:
    type ID {
        insert_symbol($2, current_dtype);
        mark_initialized($2);
        free($2);
    }
    | type ID LBRACKET RBRACKET {
        insert_symbol($2, current_dtype);
        mark_initialized($2);
        free($2);
    }
    ;

statements:
    
    | statements statement
    ;

statement:
    declaration
    | assignment SEMI
    | expr SEMI              
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    | error SEMI { yyerrok; }
    | error RBRACE { yyerrok; }
    ;

declaration:
    type id_list SEMI
    ;

type:
    INT    { strcpy(current_dtype, "int"); }
    | FLOAT  { strcpy(current_dtype, "float"); }
    | CHAR   { strcpy(current_dtype, "char"); }
    | DOUBLE { strcpy(current_dtype, "double"); }
    ;

id_list:
    var_decl
    | id_list COMMA var_decl
    ;

var_decl:
    ID {
        insert_symbol($1, current_dtype);
        free($1);
    }
    | ID LBRACKET NUMBER RBRACKET {
        insert_symbol($1, current_dtype);
        mark_initialized($1);
        free($1);
    }
    | ID ASSIGN expr {
        insert_symbol($1, current_dtype);
        check_type(current_dtype, $3); 
        mark_initialized($1); 
        free($1);
    }
    ;

assignment:
    ID ASSIGN expr {
        char *t = check_symbol_usage_and_get_type($1, 0);
        check_type(t, $3);
        mark_initialized($1);
        free($1);
    }
    | ID LBRACKET expr RBRACKET ASSIGN expr {
        char *t = check_symbol_usage_and_get_type($1, 0);
        check_type("int", $3);
        check_type(t, $6);
        mark_initialized($1);
        free($1);
    }
    ;

if_statement:
    IF LPAREN condition RPAREN LBRACE statements RBRACE %prec LOWER_THAN_ELSE
    | IF LPAREN condition RPAREN LBRACE statements RBRACE ELSE LBRACE statements RBRACE
    | IF LPAREN condition RPAREN statement %prec LOWER_THAN_ELSE
    | IF LPAREN condition RPAREN statement ELSE statement
    ;

while_statement:
    WHILE LPAREN condition RPAREN LBRACE statements RBRACE
    | WHILE LPAREN condition RPAREN statement
    ;

for_statement:
    FOR LPAREN assignment SEMI condition SEMI expr RPAREN LBRACE statements RBRACE
    | FOR LPAREN declaration condition SEMI expr RPAREN LBRACE statements RBRACE
    ;

return_statement:
    RETURN expr SEMI
    | RETURN SEMI
    ;

condition:
    expr rel_op expr
    | expr
    ;

rel_op:
    LT | GT | LE | GE | EQ | NE
    ;

expr:
    expr PLUS expr   { $$ = check_type($1, $3); }
    | expr MINUS expr  { $$ = check_type($1, $3); }
    | expr MUL expr    { $$ = check_type($1, $3); }
    | expr DIV expr    { $$ = check_type($1, $3); }
    | expr LSHIFT expr { $$ = check_type($1, "int"); }
    | expr RSHIFT expr { $$ = check_type($1, "int"); }
    | LPAREN type RPAREN expr %prec CAST { $$ = strdup(current_dtype); }
    | LPAREN expr RPAREN { $$ = $2; }
    | expr INC { $$ = $1; }
    | ID {
        $$ = check_symbol_usage_and_get_type($1, 1);
        free($1);
    }
    | ID LBRACKET expr RBRACKET {
        char *t = check_symbol_usage_and_get_type($1, 1);
        check_type("int", $3);
        $$ = t;
        free($1);
    }
    | NUMBER    { $$ = "int"; }
    | FLOAT_VAL { $$ = "float"; }
    | STRING    { $$ = "char"; }
    ;

%%

void yyerror(const char *s) {
    printf("Syntax Error at line %d\n", line);
    error_count++;
}

int main() {
    if (yyparse() == 0 && error_count == 0) {
        printf("done without error\n");
        print_symbol_table();
    } else {
        printf("\nAnalysis failed with %d error(s).\n", error_count);
    }
    return 0;
}