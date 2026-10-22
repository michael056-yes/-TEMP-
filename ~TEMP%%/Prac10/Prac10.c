#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#define MAX_INSTRUCTIONS 200
#define MAX_VARIABLES 100
#define LINE_SIZE 300
#define NAME_SIZE 50
#define REGISTER_COUNT 4


typedef struct
{
    char text[LINE_SIZE];
    int def;
    unsigned char use[MAX_VARIABLES];
    unsigned char liveIn[MAX_VARIABLES];
    unsigned char liveOut[MAX_VARIABLES];
} Instruction;

Instruction ins[MAX_INSTRUCTIONS];
char variables[MAX_VARIABLES][NAME_SIZE];
int variableCount = 0;
int instructionCount = 0;
int interference[MAX_VARIABLES][MAX_VARIABLES];
int color[MAX_VARIABLES];

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

int isIdentifierStart(char c)
{
    return isalpha((unsigned char)c) || c == '_';
}

int isIdentifierChar(char c)
{
    return isalnum((unsigned char)c) || c == '_';
}

int getVariable(const char *name, int create)
{
    int i;

    if (name[0] == '\0' || !isIdentifierStart(name[0]))
        return -1;

    for (i = 0; i < variableCount; i++)
        if (strcmp(variables[i], name) == 0)
            return i;

    if (!create || variableCount >= MAX_VARIABLES)
        return -1;

    strncpy(variables[variableCount], name, NAME_SIZE - 1);
    variables[variableCount][NAME_SIZE - 1] = '\0';
    return variableCount++;
}

int isNumber(const char *s)
{
    char *end;

    if (s == NULL || *s == '\0')
        return 0;
    (void)strtod(s, &end);
    return end != s && *end == '\0';
}

void splitAssignment(const char *text, char *lhs, char *rhs)
{
    const char *eq = strchr(text, '=');
    size_t len;
    char *semi;

    lhs[0] = '\0';
    rhs[0] = '\0';
    if (eq == NULL)
        return;

    len = (size_t)(eq - text);
    if (len >= NAME_SIZE)
        len = NAME_SIZE - 1;
    strncpy(lhs, text, len);
    lhs[len] = '\0';
    strcpy(rhs, eq + 1);

    semi = strchr(rhs, ';');
    if (semi != NULL)
        *semi = '\0';
}

void collectUses(int instructionIndex, const char *rhs)
{
    int i = 0;
    while (rhs[i] != '\0')
    {
        if (isIdentifierStart(rhs[i]))
        {
            char token[NAME_SIZE];
            int k = 0;
            while (rhs[i] != '\0' && isIdentifierChar(rhs[i]))
            {
                if (k < NAME_SIZE - 1)
                    token[k++] = rhs[i];
                i++;
            }
            token[k] = '\0';
            {
                int v = getVariable(token, 1);
                if (v >= 0)
                    ins[instructionIndex].use[v] = 1;
            }
        }
        else
        {
            i++;
        }
    }
}

void prepareInstructions(void)
{
    int i;

    for (i = 0; i < instructionCount; i++)
    {
        char lhs[NAME_SIZE], rhs[LINE_SIZE];
        int def;

        splitAssignment(ins[i].text, lhs, rhs);
        if (lhs[0] == '\0')
        {
            ins[i].def = -1;
            continue;
        }

        def = getVariable(lhs, 1);
        ins[i].def = def;
        collectUses(i, rhs);
    }
}

void calculateLiveness(void)
{
    int changed = 1;

    while (changed)
    {
        int i, v;
        changed = 0;

        for (i = instructionCount - 1; i >= 0; i--)
        {
            unsigned char newOut[MAX_VARIABLES] = {0};
            unsigned char newIn[MAX_VARIABLES] = {0};

            if (i + 1 < instructionCount)
                for (v = 0; v < variableCount; v++)
                    newOut[v] = ins[i + 1].liveIn[v];

            for (v = 0; v < variableCount; v++)
            {
                int definedHere = (ins[i].def == v);
                newIn[v] = ins[i].use[v] || (newOut[v] && !definedHere);
            }

            for (v = 0; v < variableCount; v++)
            {
                if (ins[i].liveOut[v] != newOut[v] ||
                    ins[i].liveIn[v] != newIn[v])
                    changed = 1;

                ins[i].liveOut[v] = newOut[v];
                ins[i].liveIn[v] = newIn[v];
            }
        }
    }
}

void addEdge(int a, int b)
{
    if (a >= 0 && b >= 0 && a != b)
    {
        interference[a][b] = 1;
        interference[b][a] = 1;
    }
}

void buildInterferenceGraph(void)
{
    int i, a, b, v;

    memset(interference, 0, sizeof(interference));

    for (i = 0; i < instructionCount; i++)
    {
        for (a = 0; a < variableCount; a++)
            for (b = a + 1; b < variableCount; b++)
            {
                if (ins[i].liveIn[a] && ins[i].liveIn[b])
                    addEdge(a, b);
                if (ins[i].liveOut[a] && ins[i].liveOut[b])
                    addEdge(a, b);
            }

        v = ins[i].def;
        if (v >= 0)
            for (a = 0; a < variableCount; a++)
                if (ins[i].liveOut[a])
                    addEdge(v, a);
    }
}

int activeDegree(int v, const unsigned char active[MAX_VARIABLES])
{
    int i, degree = 0;
    for (i = 0; i < variableCount; i++)
        if (active[i] && interference[v][i])
            degree++;
    return degree;
}

void colorGraph(void)
{
    unsigned char active[MAX_VARIABLES] = {0};
    int stack[MAX_VARIABLES];
    int stackCount = 0;
    int remaining = variableCount;
    int i;

    for (i = 0; i < variableCount; i++)
    {
        active[i] = 1;
        color[i] = -2;
    }

    while (remaining > 0)
    {
        int chosen = -1;

        for (i = 0; i < variableCount; i++)
            if (active[i] && activeDegree(i, active) < REGISTER_COUNT)
            {
                chosen = i;
                break;
            }

        if (chosen == -1)
        {
            int bestDegree = -1;
            for (i = 0; i < variableCount; i++)
                if (active[i])
                {
                    int d = activeDegree(i, active);
                    if (d > bestDegree)
                    {
                        bestDegree = d;
                        chosen = i;
                    }
                }
        }

        stack[stackCount++] = chosen;
        active[chosen] = 0;
        remaining--;
    }

    while (stackCount > 0)
    {
        int v = stack[--stackCount];
        unsigned char unavailable[REGISTER_COUNT] = {0};
        int neighbor, r;

        for (neighbor = 0; neighbor < variableCount; neighbor++)
            if (interference[v][neighbor] &&
                color[neighbor] >= 0 && color[neighbor] < REGISTER_COUNT)
                unavailable[color[neighbor]] = 1;

        color[v] = -1;
        for (r = 0; r < REGISTER_COUNT; r++)
            if (!unavailable[r])
            {
                color[v] = r;
                break;
            }
    }
}

int findBinaryOperator(const char *rhs, int *position)
{
    int i;
    for (i = 1; rhs[i] != '\0'; i++)
    {
        if ((rhs[i] == '+' || rhs[i] == '-' ||
             rhs[i] == '*' || rhs[i] == '/') &&
            rhs[i - 1] != 'e' && rhs[i - 1] != 'E')
        {
            *position = i;
            return rhs[i];
        }
    }
    return 0;
}

void getSourceOperand(FILE *out, const char *operand,
                      const char *scratch, char *result)
{
    int v;

    if (isNumber(operand))
    {
        snprintf(result, 40, "#%s", operand);
        return;
    }

    v = getVariable(operand, 0);
    if (v < 0)
    {
        snprintf(result, 40, "%s", operand);
        return;
    }

    if (color[v] >= 0)
        snprintf(result, 40, "R%d", color[v]);
    else
    {
        fprintf(out, "    LOAD %s, [%s]\n", scratch, operand);
        snprintf(result, 40, "%s", scratch);
    }
}

void generateRegisterCode(FILE *out, const char *text)
{
    char lhs[NAME_SIZE], rhs[LINE_SIZE];
    char op1[LINE_SIZE], op2[LINE_SIZE];
    int pos, op, d;
    char src1[40], src2[40], dest[40];
    char mnemonic[10];

    splitAssignment(text, lhs, rhs);
    if (lhs[0] == '\0')
    {
        fprintf(out, "    ; unsupported TAC instruction: %s\n", text);
        return;
    }

    d = getVariable(lhs, 0);
    if (d < 0)
        return;

    op = findBinaryOperator(rhs, &pos);
    if (op != 0)
    {
        size_t len = (size_t)pos;
        if (len >= sizeof(op1)) len = sizeof(op1) - 1;
        strncpy(op1, rhs, len);
        op1[len] = '\0';
        strcpy(op2, rhs + pos + 1);

        getSourceOperand(out, op1, "S0", src1);
        getSourceOperand(out, op2, "S1", src2);

        if (color[d] >= 0)
            snprintf(dest, sizeof(dest), "R%d", color[d]);
        else
            strcpy(dest, "S2");

        switch (op)
        {
            case '+': strcpy(mnemonic, "ADD"); break;
            case '-': strcpy(mnemonic, "SUB"); break;
            case '*': strcpy(mnemonic, "MUL"); break;
            default:  strcpy(mnemonic, "DIV"); break;
        }

        fprintf(out, "    %s %s, %s, %s\n", mnemonic, dest, src1, src2);
        if (color[d] < 0)
            fprintf(out, "    STORE [%s], S2\n", lhs);
        return;
    }

    if (isNumber(rhs))
    {
        if (color[d] >= 0)
            fprintf(out, "    MOV R%d, #%s\n", color[d], rhs);
        else
            fprintf(out, "    MOV S2, #%s\n    STORE [%s], S2\n", rhs, lhs);
        return;
    }

    {
        int s = getVariable(rhs, 0);
        if (s < 0)
        {
            fprintf(out, "    ; unsupported RHS in: %s\n", text);
            return;
        }

        if (color[d] >= 0 && color[s] >= 0)
        {
            if (color[d] != color[s])
                fprintf(out, "    MOV R%d, R%d\n", color[d], color[s]);
        }
        else if (color[d] >= 0 && color[s] < 0)
        {
            fprintf(out, "    LOAD R%d, [%s]\n", color[d], rhs);
        }
        else if (color[d] < 0 && color[s] >= 0)
        {
            fprintf(out, "    STORE [%s], R%d\n", lhs, color[s]);
        }
        else
        {
            fprintf(out, "    LOAD S0, [%s]\n    STORE [%s], S0\n", rhs, lhs);
        }
    }
}

int main(void)
{
    FILE *in, *out;
    char line[LINE_SIZE];
    int i, a, b;

    in = fopen("input.txt", "r");
    if (in == NULL)
    {
        fprintf(stderr, "Error: cannot open input.txt\n");
        return 1;
    }

    while (instructionCount < MAX_INSTRUCTIONS &&
           fgets(line, sizeof(line), in) != NULL)
    {
        line[strcspn(line, "\r\n")] = '\0';
        removeSpaces(line);
        removeLineNumber(line);

        if (line[0] == '\0' || line[0] == '#')
            continue;
        if (strcmp(line, "{") == 0 || strcmp(line, "}") == 0)
            continue;

        strcpy(ins[instructionCount].text, line);
        ins[instructionCount].def = -1;
        instructionCount++;
    }
    fclose(in);

    prepareInstructions();
    calculateLiveness();
    buildInterferenceGraph();
    colorGraph();

    out = fopen("output.txt", "w");
    if (out == NULL)
    {
        fprintf(stderr, "Error: cannot create output.txt\n");
        return 1;
    }

    fprintf(out, "Input TAC:\n\n");
    for (i = 0; i < instructionCount; i++)
        fprintf(out, "%d: %s\n", 100 + i, ins[i].text);

    fprintf(out, "\nInterference Graph Edges:\n");
    {
        int edgeCount = 0;
        for (a = 0; a < variableCount; a++)
            for (b = a + 1; b < variableCount; b++)
                if (interference[a][b])
                {
                    fprintf(out, "  %s -- %s\n", variables[a], variables[b]);
                    edgeCount++;
                }
        if (edgeCount == 0)
            fprintf(out, "  (no edges)\n");
    }

    fprintf(out, "\nRegister Allocation (Greedy Graph Coloring, %d registers):\n",
            REGISTER_COUNT);
    for (i = 0; i < variableCount; i++)
    {
        if (color[i] >= 0)
            fprintf(out, "  %-10s -> R%d\n", variables[i], color[i]);
        else
            fprintf(out, "  %-10s -> SPILL (memory)\n", variables[i]);
    }

    fprintf(out, "\nGenerated Register-Based Pseudo-Assembly:\n\n");
    fprintf(out, "  ; Three-operand instruction format: OP destination, source1, source2\n");
    fprintf(out, "  ; S0-S2 are scratch registers used only for spilled values.\n\n");
    for (i = 0; i < instructionCount; i++)
    {
        fprintf(out, "%d: %s\n", 100 + i, ins[i].text);
        generateRegisterCode(out, ins[i].text);
    }

    fclose(out);
    printf("Complete. Results written to output.txt\n");
    return 0;
}