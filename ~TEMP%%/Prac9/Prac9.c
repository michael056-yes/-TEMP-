#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#define MAX_LINES 200
#define LINE_SIZE 300

char original[MAX_LINES][LINE_SIZE];
char optimized[MAX_LINES][LINE_SIZE];
int lineCount = 0;

void removeSpaces(char *s)
{
    char temp[LINE_SIZE];
    int i, j = 0;

    for (i = 0; s[i] != '\0'; i++)
        if (!isspace((unsigned char)s[i]))
            temp[j++] = s[i];

    temp[j] = '\0';
    strcpy(s, temp);
}

void removeLineNumber(char *s)
{
    char *colon = strchr(s, ':');
    char *p;
    int onlyDigits = 1;

    if (colon == NULL || colon == s)
        return;

    for (p = s; p < colon; p++)
    {
        if (!isdigit((unsigned char)*p))
        {
            onlyDigits = 0;
            break;
        }
    }

    if (onlyDigits)
        memmove(s, colon + 1, strlen(colon + 1) + 1);
}

int foldConstants(const char *rhs, char *result)
{
    char *endLeft;
    char *endRight;
    double left, right, value;
    char op;

    left = strtod(rhs, &endLeft);
    if (endLeft == rhs || *endLeft == '\0')
        return 0;

    op = *endLeft;
    if (op != '+' && op != '-' && op != '*' && op != '/')
        return 0;

    right = strtod(endLeft + 1, &endRight);
    if (endRight == endLeft + 1 || *endRight != '\0')
        return 0;

    switch (op)
    {
        case '+': value = left + right; break;
        case '-': value = left - right; break;
        case '*': value = left * right; break;
        case '/':
            if (right == 0.0)
                return 0;
            value = left / right;
            break;
        default:
            return 0;
    }

    snprintf(result, 100, "%g", value);
    return 1;
}

void optimizeLine(const char *line, char *out)
{
    char lhs[100], rhs[200], value[100];
    const char *eq;
    char *semi;
    int hadSemicolon;
    size_t lhsLength;

    strcpy(out, line);
    eq = strchr(line, '=');
    if (eq == NULL)
        return;

    lhsLength = (size_t)(eq - line);
    if (lhsLength == 0 || lhsLength >= sizeof(lhs))
        return;

    strncpy(lhs, line, lhsLength);
    lhs[lhsLength] = '\0';
    strcpy(rhs, eq + 1);

    semi = strchr(rhs, ';');
    hadSemicolon = (semi != NULL);
    if (semi != NULL)
        *semi = '\0';

    if (foldConstants(rhs, value))
        snprintf(out, LINE_SIZE, "%s=%s%s", lhs, value,
                 hadSemicolon ? ";" : "");
}

int main(void)
{
    FILE *in, *out;
    char line[LINE_SIZE];
    int i;

    in = fopen("input.txt", "r");
    if (in == NULL)
    {
        fprintf(stderr, "Error: cannot open input.txt\n");
        return 1;
    }

    while (lineCount < MAX_LINES && fgets(line, sizeof(line), in) != NULL)
    {
        line[strcspn(line, "\r\n")] = '\0';
        removeSpaces(line);
        removeLineNumber(line);

        if (line[0] == '\0' || line[0] == '#')
            continue;

        strcpy(original[lineCount], line);
        optimizeLine(original[lineCount], optimized[lineCount]);
        lineCount++;
    }
    fclose(in);

    out = fopen("output.txt", "w");
    if (out == NULL)
    {
        fprintf(stderr, "Error: cannot create output.txt\n");
        return 1;
    }

    fprintf(out, "Given TAC:\n\n");
    for (i = 0; i < lineCount; i++)
        fprintf(out, "%d: %s\n", 100 + i, original[i]);

    fprintf(out, "\nOptimized TAC:\n\n");
    for (i = 0; i < lineCount; i++)
        fprintf(out, "%d: %s\n", 100 + i, optimized[i]);

    fclose(out);
    printf("Complete. Results written to output.txt\n");
    return 0;
}