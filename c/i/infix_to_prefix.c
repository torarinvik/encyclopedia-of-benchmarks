/* Convert fully parenthesized bounded ASCII infix expressions to prefix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_EXPRESSION 256
static int operand(int64_t c) { return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); }
static int operation(int64_t c) { return c == '+' || c == '-' || c == '*' || c == '/' || c == '^'; }
static int precedence(int64_t c) { return c == '+' || c == '-' ? 1 : (c == '*' || c == '/' ? 2 : 3); }

static int valid_expression(const int64_t *input, size_t length) {
    unsigned char stage[MAX_EXPRESSION];
    size_t depth = 0;
    int root_done = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t ch = input[i];
        if (depth == 0) {
            if (root_done) return 0;
            if (operand(ch)) root_done = 1;
            else if (ch == '(') stage[depth++] = 0;
            else return 0;
        } else if (stage[depth - 1] == 0 || stage[depth - 1] == 2) {
            if (operand(ch)) stage[depth - 1] = stage[depth - 1] == 0 ? 1 : 3;
            else if (ch == '(' && depth < MAX_EXPRESSION) stage[depth++] = 0;
            else return 0;
        } else if (stage[depth - 1] == 1) {
            if (!operation(ch)) return 0;
            stage[depth - 1] = 2;
        } else {
            if (ch != ')') return 0;
            --depth;
            if (depth == 0) root_done = 1;
            else if (stage[depth - 1] == 0) stage[depth - 1] = 1;
            else if (stage[depth - 1] == 2) stage[depth - 1] = 3;
            else return 0;
        }
    }
    return depth == 0 && root_done;
}

int64_t infix_to_prefix(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (length > MAX_EXPRESSION || (length > 0 && input == NULL)) return -1;
    if (length == 0) return 0;
    if (!valid_expression(input, length)) return -1;
    uint8_t stack[MAX_EXPRESSION], postfix[MAX_EXPRESSION];
    size_t top = 0, count = 0;
    for (size_t i = length; i > 0; --i) {
        int64_t ch = input[i - 1];
        if (operand(ch)) postfix[count++] = (uint8_t)ch;
        else if (ch == ')') stack[top++] = ')';
        else if (ch == '(') {
            while (top > 0 && stack[top - 1] != ')') postfix[count++] = stack[--top];
            if (top > 0) --top;
        } else {
            while (top > 0 && stack[top - 1] != ')' && precedence(ch) < precedence(stack[top - 1]))
                postfix[count++] = stack[--top];
            stack[top++] = (uint8_t)ch;
        }
    }
    while (top > 0) postfix[count++] = stack[--top];
    if (capacity < count || (count > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = postfix[count - 1 - i];
    return (int64_t)count;
}
