/* Evaluate bounded fully-parenthesized integer expressions with two stacks. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1000000001;

std::int64_t apply_operator(std::int64_t opcode, std::int64_t left, std::int64_t right) noexcept
{
    std::int64_t result;
    if (opcode == '+') result = left + right;
    else if (opcode == '-') result = left - right;
    else if (opcode == '*') result = left * right;
    else if (opcode == '/') {
        if (right == 0 || left % right != 0) return invalid_result;
        result = left / right;
    } else return invalid_result;
    return result < -1000000000 || result > 1000000000 ? invalid_result : result;
}
}

extern "C" std::int64_t dijkstras_two_stack_algorithm(const std::int64_t *values,
                                                        std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > 511) return invalid_result;
    std::int64_t operands[256], operators[256];
    std::size_t operand_top = 0, operator_top = 0, parentheses = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t token = values[index];
        if (token >= '0' && token <= '9') {
            if (operand_top == 256) return invalid_result;
            operands[operand_top++] = token - '0';
        } else if (token == '(') {
            if (++parentheses > 128) return invalid_result;
        } else if (token == '+' || token == '-' || token == '*' || token == '/') {
            if (operator_top == 256) return invalid_result;
            operators[operator_top++] = token;
        } else if (token == ')') {
            if (parentheses == 0 || operator_top == 0 || operand_top < 2) return invalid_result;
            --parentheses;
            const std::int64_t opcode = operators[--operator_top];
            const std::int64_t right = operands[--operand_top];
            const std::int64_t left = operands[--operand_top];
            const std::int64_t result = apply_operator(opcode, left, right);
            if (result == invalid_result) return invalid_result;
            operands[operand_top++] = result;
        } else return invalid_result;
    }
    return parentheses == 0 && operator_top == 0 && operand_top == 1 ? operands[0] : invalid_result;
}
