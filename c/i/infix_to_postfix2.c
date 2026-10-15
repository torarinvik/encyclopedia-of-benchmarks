/* Convert a bounded ASCII infix expression with the source's operator stack. */
#include <stddef.h>
#include <stdint.h>

#define MAX_EXPRESSION 24
#define MAX_STACK 10

static int operand(int64_t c) {
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
static int operator(int64_t c) { return c == '+' || c == '-' || c == '*' || c == '/' || c == '%'; }
static int precedence(int64_t c) { return c == '*' || c == '/' || c == '%' ? 1 : 0; }

int64_t infix_to_postfix2(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length == 0 || length > MAX_EXPRESSION) return -1;
    uint8_t stack[MAX_STACK], result[MAX_EXPRESSION + 1];
    size_t top = 0, count = 0;
    int expect_operand = 1;
    for (size_t i = 0; i < length; ++i) {
        const int64_t ch = input[i];
        if (operand(ch)) {
            if (!expect_operand) return -1;
            result[count++] = (uint8_t)ch;
            expect_operand = 0;
        } else if (ch == '(') {
            if (!expect_operand || top == MAX_STACK) return -1;
            stack[top++] = (uint8_t)ch;
        } else if (ch == ')') {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(') result[count++] = stack[--top];
            if (top == 0) return -1;
            --top;
            expect_operand = 0;
        } else if (operator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' && precedence(ch) <= precedence(stack[top - 1]))
                result[count++] = stack[--top];
            if (top == MAX_STACK) return -1;
            stack[top++] = (uint8_t)ch;
            expect_operand = 1;
        } else return -1;
    }
    if (expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        result[count++] = stack[--top];
    }
    result[count++] = 0;
    if (output == NULL || output_capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = result[i];
    return (int64_t)count;
}
