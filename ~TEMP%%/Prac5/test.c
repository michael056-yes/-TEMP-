/*
 * Test input for the Prac5 syntax analyzer.
 * The marked errors are intentional and should be reported by the parser.
 */

int calculate(int value, int limit) {
    int result;
    result = value + limit;

    if (result > 0) {
        result++;
    } else {
        result = result - 1;
    }

    return result;
}

int main() {
    int number;
    int answer;

    number = 10
    answer = calculate(number, 5);

    if (answer < ) {
        answer = answer + 1;
    }

    while (answer > 0 {
        answer = answer - 1;
    }

    int broken, ;

    for (number = 0; number < 3; number++) {
        answer = answer + number;
    }

    return answer;
}