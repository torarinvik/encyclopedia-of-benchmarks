#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_EXPRESSION_BYTES 255
#define MAX_PARSEABLE_INPUT_LENGTH 257
#define MAX_OPERANDS 16
#define MAX_OPERATORS 15
#define MAX_LITERAL_BYTES 16
#define MAX_LITERAL_VALUE 1000000.0
#define MAX_ABSOLUTE_INTERMEDIATE 1000000000000.0
#define INVALID_RESULT (-1.0e300)

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

static int is_ascii_whitespace(int64_t value)
{
    return value == ' ' || value == '\t' || value == '\n' ||
           value == '\v' || value == '\f' || value == '\r';
}

static int is_ascii_digit(int64_t value)
{
    return value >= '0' && value <= '9';
}

static int is_operator(int64_t value)
{
    return value == '+' || value == '-' || value == '*' ||
           value == '/' || value == '^';
}

static int precedence(char op)
{
    if (op == '^') return 3;
    if (op == '*' || op == '/') return 2;
    return 1;
}

static int apply_top(double *numbers, size_t *number_count,
                     const char *operators, size_t *operator_count)
{
    if (*number_count < 2 || *operator_count == 0) return 0;
    const char op = operators[--*operator_count];
    const double right = numbers[--*number_count];
    const double left = numbers[--*number_count];
    double value;

    switch (op) {
        case '+': value = left + right; break;
        case '-': value = left - right; break;
        case '*': value = left * right; break;
        case '/':
            if (right == 0.0) return 0;
            value = left / right;
            break;
        case '^': value = pow(left, right); break;
        default: return 0;
    }
    if (!isfinite(value) || fabs(value) > MAX_ABSOLUTE_INTERMEDIATE) return 0;
    numbers[(*number_count)++] = value;
    return 1;
}

double shunting_yard(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 2 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > MAX_EXPRESSION_BYTES) return INVALID_RESULT;
    const size_t byte_count = (size_t)input[0];
    if (input_length != byte_count + 1) return INVALID_RESULT;
    for (size_t i = 0; i < byte_count; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 0x7f) return INVALID_RESULT;
    }

    double numbers[MAX_OPERANDS];
    char operators[MAX_OPERATORS];
    size_t number_count = 0;
    size_t operator_count = 0;
    size_t operand_count = 0;
    size_t parsed_operator_count = 0;
    size_t position = 1;
    int expect_number = 1;

    while (position <= byte_count) {
        while (position <= byte_count && is_ascii_whitespace(input[position])) ++position;
        if (position > byte_count) break;

        if (expect_number) {
            const size_t start = position;
            size_t integer_digits = 0;
            double value = 0.0;
            while (position <= byte_count && is_ascii_digit(input[position])) {
                value = rounded_add(rounded_multiply(value, 10.0),
                                    (double)(input[position] - '0'));
                ++integer_digits;
                ++position;
            }
            if (integer_digits == 0) return INVALID_RESULT;

            if (position <= byte_count && input[position] == '.') {
                ++position;
                size_t fractional_digits = 0;
                double scale = 0.1;
                while (position <= byte_count && is_ascii_digit(input[position])) {
                    const double term = rounded_multiply(
                        (double)(input[position] - '0'), scale);
                    value = rounded_add(value, term);
                    scale = rounded_divide(scale, 10.0);
                    ++fractional_digits;
                    ++position;
                }
                if (fractional_digits == 0) return INVALID_RESULT;
            }

            const size_t literal_length = position - start;
            if (literal_length > MAX_LITERAL_BYTES ||
                value < 0.0 || value > MAX_LITERAL_VALUE ||
                operand_count >= MAX_OPERANDS) return INVALID_RESULT;

            numbers[number_count++] = value;
            ++operand_count;
            expect_number = 0;
        } else {
            const int64_t raw_operator = input[position];
            if (!is_operator(raw_operator) ||
                parsed_operator_count >= MAX_OPERATORS) return INVALID_RESULT;
            const char current = (char)raw_operator;
            while (operator_count > 0) {
                const char previous = operators[operator_count - 1];
                const int previous_precedence = precedence(previous);
                const int current_precedence = precedence(current);
                if (previous_precedence < current_precedence ||
                    (previous_precedence == current_precedence && current == '^')) break;
                if (!apply_top(numbers, &number_count, operators, &operator_count))
                    return INVALID_RESULT;
            }
            operators[operator_count++] = current;
            ++position;
            ++parsed_operator_count;
            expect_number = 1;
        }
    }

    if (expect_number || operand_count == 0 ||
        parsed_operator_count + 1 != operand_count) return INVALID_RESULT;
    while (operator_count > 0) {
        if (!apply_top(numbers, &number_count, operators, &operator_count))
            return INVALID_RESULT;
    }
    if (number_count != 1) return INVALID_RESULT;
    return numbers[0];
}
