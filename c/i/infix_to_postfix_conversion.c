/* Shunting-yard conversion with Python source precedence and associativity. */
#include <stddef.h>
#include <stdint.h>

#define MAX_EXPRESSION 256
#define MAX_OUTPUT (2 * MAX_EXPRESSION)

static int is_operand(int64_t ch) {
    return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
}
static int is_operator(int64_t ch) { return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^'; }
static int precedence(int64_t ch) { return ch == '+' || ch == '-' ? 1 : (ch == '*' || ch == '/' ? 2 : 3); }

static void emit_token(uint8_t *result, size_t *count, uint8_t token) {
    if (*count > 0) result[(*count)++] = ' ';
    result[(*count)++] = token;
}

int64_t infix_to_postfix_conversion(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1) return -1;
    const int64_t expression_length = input[0];
    if (expression_length < 0 || expression_length > MAX_EXPRESSION ||
        length != 1 + (size_t)expression_length) return -1;
    uint8_t stack[MAX_EXPRESSION], result[MAX_OUTPUT];
    size_t top = 0, count = 0;
    int expect_operand = 1;
    for (size_t i = 0; i < (size_t)expression_length; ++i) {
        const int64_t ch = input[1 + i];
        if (is_operand(ch)) {
            if (!expect_operand) return -1;
            emit_token(result, &count, (uint8_t)ch);
            expect_operand = 0;
        } else if (ch == '(') {
            if (!expect_operand || top == MAX_EXPRESSION) return -1;
            stack[top++] = (uint8_t)ch;
        } else if (ch == ')') {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(') emit_token(result, &count, stack[--top]);
            if (top == 0) return -1;
            --top;
            expect_operand = 0;
        } else if (is_operator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' &&
                   (precedence(ch) < precedence(stack[top - 1]) ||
                    (precedence(ch) == precedence(stack[top - 1]) && ch != '^'))) {
                emit_token(result, &count, stack[--top]);
            }
            if (top == MAX_EXPRESSION) return -1;
            stack[top++] = (uint8_t)ch;
            expect_operand = 1;
        } else return -1;
    }
    if (expression_length != 0 && expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        emit_token(result, &count, stack[--top]);
    }
    result[count++] = 0;
    if (output == NULL || output_capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = result[i];
    return (int64_t)count;
}
