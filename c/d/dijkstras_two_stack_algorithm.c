/* Evaluate bounded fully-parenthesized integer expressions with two stacks. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1000000001)
#define MAX_INPUT_LENGTH 511
#define MAX_STACK 256
#define MAX_RESULT INT64_C(1000000000)

static int64_t apply_operator(int64_t opcode, int64_t left, int64_t right)
{
    int64_t result;
    if (opcode == '+') result = left + right;
    else if (opcode == '-') result = left - right;
    else if (opcode == '*') result = left * right;
    else if (opcode == '/') {
        if (right == 0 || left % right != 0) return INVALID_RESULT;
        result = left / right;
    } else return INVALID_RESULT;
    return result < -MAX_RESULT || result > MAX_RESULT ? INVALID_RESULT : result;
}

int64_t dijkstras_two_stack_algorithm(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int64_t operands[MAX_STACK], operators[MAX_STACK];
    size_t operand_top = 0, operator_top = 0, parentheses = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t token = values[index];
        if (token >= '0' && token <= '9') {
            if (operand_top == MAX_STACK) return INVALID_RESULT;
            operands[operand_top++] = token - '0';
        } else if (token == '(') {
            if (++parentheses > MAX_STACK / 2) return INVALID_RESULT;
        } else if (token == '+' || token == '-' || token == '*' || token == '/') {
            if (operator_top == MAX_STACK) return INVALID_RESULT;
            operators[operator_top++] = token;
        } else if (token == ')') {
            if (parentheses == 0 || operator_top == 0 || operand_top < 2) return INVALID_RESULT;
            --parentheses;
            const int64_t opcode = operators[--operator_top];
            const int64_t right = operands[--operand_top];
            const int64_t left = operands[--operand_top];
            const int64_t result = apply_operator(opcode, left, right);
            if (result == INVALID_RESULT) return INVALID_RESULT;
            operands[operand_top++] = result;
        } else return INVALID_RESULT;
    }
    return parentheses == 0 && operator_top == 0 && operand_top == 1 ? operands[0] : INVALID_RESULT;
}
