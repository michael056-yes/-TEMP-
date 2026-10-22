#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define MAX 500
#define REG_COUNT 4

char code[MAX][150];
int ncode = 0;
int tempNo = 1;

char regVar[REG_COUNT][50];
int regUsed[REG_COUNT];

void removeSpaces(char *s)
{
    char t[300];
    int i, j = 0;

    for (i = 0; s[i]; i++)
    {
        if (!isspace((unsigned char)s[i]))
            t[j++] = s[i];
    }
    t[j] = '\0';
    strcpy(s, t);
}

int getreg(char *var)
{
    int i;

    for (i = 0; i < REG_COUNT; i++)
    {
        if (regUsed[i] && strcmp(regVar[i], var) == 0)
            return i;
    }

    for (i = 0; i < REG_COUNT; i++)
    {
        if (!regUsed[i])
        {
            regUsed[i] = 1;
            strcpy(regVar[i], var);
            return i;
        }
    }

    strcpy(regVar[0], var);
    return 0;
}

void expression(char *s, int *p, char *out);

void factor(char *s, int *p, char *out)
{
    char token[50];
    int k = 0;

    if (s[*p] == '(')
    {
        (*p)++;
        expression(s, p, out);
        if (s[*p] == ')')
            (*p)++;
        return;
    }

    while (s[*p] && (isalnum((unsigned char)s[*p]) || s[*p] == '_' || s[*p] == '.'))
    {
        token[k++] = s[(*p)++];
    }
    token[k] = '\0';
    strcpy(out, token);
}

void term(char *s, int *p, char *out)
{
    char left[50], right[50], temp[50];
    char op;

    factor(s, p, left);

    while (s[*p] == '*' || s[*p] == '/')
    {
        op = s[(*p)++];
        factor(s, p, right);

        sprintf(temp, "t%d", tempNo++);
        sprintf(code[ncode++], "%s=%s%c%s", temp, left, op, right);
        strcpy(left, temp);
    }

    strcpy(out, left);
}

void expression(char *s, int *p, char *out)
{
    char left[50], right[50], temp[50];
    char op;

    term(s, p, left);

    while (s[*p] == '+' || s[*p] == '-')
    {
        op = s[(*p)++];
        term(s, p, right);

        sprintf(temp, "t%d", tempNo++);
        sprintf(code[ncode++], "%s=%s%c%s", temp, left, op, right);
        strcpy(left, temp);
    }

    strcpy(out, left);
}

void generateAssignment(char *line)
{
    char lhs[50], rhs[200], result[50];
    char *eq, *semi;
    int p = 0;

    eq = strchr(line, '=');
    if (eq == NULL)
        return;

    strncpy(lhs, line, eq - line);
    lhs[eq - line] = '\0';

    strcpy(rhs, eq + 1);
    semi = strchr(rhs, ';');
    if (semi != NULL)
        *semi = '\0';

    expression(rhs, &p, result);
    sprintf(code[ncode++], "%s=%s;", lhs, result);
}

void generateAssembly(char *line)
{
    char lhs[50], op1[50], op2[50];
    char op;
    int r1, r2;

    if (sscanf(line, "%[^=]=%[^;];", lhs, op1) == 2)
    {
        if (sscanf(op1, "%[^+-*/]%c%s", op1, &op, op2) != 3)
        {
            r1 = getreg(op1);
            printf("MOV R%d, %s\n", r1, op1);
            printf("MOV %s, R%d\n", lhs, r1);
            return;
        }
    }

    if (sscanf(line, "%[^=]=%[^+-*/]%c%s", lhs, op1, &op, op2) == 4)
    {
        r1 = getreg(op1);
        r2 = getreg(op2);

        printf("MOV R%d, %s\n", r1, op1);

        switch (op)
        {
            case '+':
                printf("ADD R%d, %s\n", r1, op2);
                break;
            case '-':
                printf("SUB R%d, %s\n", r1, op2);
                break;
            case '*':
                printf("MUL R%d, %s\n", r1, op2);
                break;
            case '/':
                printf("DIV R%d, %s\n", r1, op2);
                break;
        }

        printf("MOV %s, R%d\n", lhs, r1);
        strcpy(regVar[r1], lhs);
        regUsed[r1] = 1;
    }
}

int main()
{
    FILE *fp;
    char lines[MAX][300];
    int total = 0, i;

    fp = fopen("input.txt", "r");
    if (fp == NULL)
    {
        printf("Cannot open input.txt\n");
        return 1;
    }

    while (total < MAX && fgets(lines[total], sizeof(lines[total]), fp))
    {
        lines[total][strcspn(lines[total], "\n")] = '\0';
        if (strlen(lines[total]) > 0)
            total++;
    }
    fclose(fp);

    for (i = 0; i < total; i++)
    {
        char line[300];
        strcpy(line, lines[i]);
        removeSpaces(line);

        if (strcmp(line, "{") == 0 || strcmp(line, "}") == 0)
            continue;

        if (strchr(line, '=') != NULL)
            generateAssignment(line);
    }

    printf("Three Address Code:\n\n");
    for (i = 0; i < ncode; i++)
    {
        printf("%d: %s\n", 100 + i, code[i]);
    }

    printf("\nAssembly Code:\n\n");
    for (i = 0; i < ncode; i++)
    {
        generateAssembly(code[i]);
    }

    return 0;
}