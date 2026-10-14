/* Evaluate bounded integer postfix expressions with an explicit operand stack. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1000000001)
#define MAX_TOKENS 256
#define MAX_OPERAND INT64_C(1000000)
#define MAX_RESULT INT64_C(1000000000)

static int64_t apply(int64_t opcode, int64_t left, int64_t right)
{
    int64_t value;
    switch (opcode) {
    case 1: value = left + right; break;
    case 2: value = left - right; break;
    case 3: value = left * right; break;
    case 4: {
        if (right == 0) return INVALID_RESULT;
        const int64_t magnitude_left = left < 0 ? -left : left;
        const int64_t magnitude_right = right < 0 ? -right : right;
        const int64_t quotient = magnitude_left / magnitude_right;
        value = ((left < 0) != (right < 0)) ? -quotient : quotient;
        break;
    }
    default: return INVALID_RESULT;
    }
    return value < -MAX_RESULT || value > MAX_RESULT ? INVALID_RESULT : value;
}

int64_t postfix_evaluation(const int64_t *values, size_t length)
{
    if (length < 2 || length > 2 * MAX_TOKENS || length % 2 != 0) return INVALID_RESULT;
    const size_t token_count = length / 2;
    int64_t stack[MAX_TOKENS];
    size_t top = 0;
    for (size_t token = 0; token < token_count; ++token) {
        const int64_t opcode = values[2 * token];
        const int64_t operand = values[2 * token + 1];
        if (opcode == 0) {
            if (operand < -MAX_OPERAND || operand > MAX_OPERAND) return INVALID_RESULT;
            stack[top++] = operand;
        } else {
            if (opcode < 1 || opcode > 4 || operand != 0 || top < 2) return INVALID_RESULT;
            const int64_t right = stack[--top];
            const int64_t left = stack[--top];
            const int64_t result = apply(opcode, left, right);
            if (result == INVALID_RESULT) return INVALID_RESULT;
            stack[top++] = result;
        }
    }
    return top == 1 ? stack[0] : INVALID_RESULT;
}
