/* Evaluate bounded integer postfix expressions with an explicit operand stack. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1000000001;
std::int64_t apply(std::int64_t opcode, std::int64_t left, std::int64_t right) noexcept
{
    std::int64_t value;
    switch (opcode) {
    case 1: value = left + right; break;
    case 2: value = left - right; break;
    case 3: value = left * right; break;
    case 4: {
        if (right == 0) return invalid_result;
        const std::int64_t magnitude_left = left < 0 ? -left : left;
        const std::int64_t magnitude_right = right < 0 ? -right : right;
        const std::int64_t quotient = magnitude_left / magnitude_right;
        value = ((left < 0) != (right < 0)) ? -quotient : quotient;
        break;
    }
    default: return invalid_result;
    }
    return value < -1000000000 || value > 1000000000 ? invalid_result : value;
}
}

extern "C" std::int64_t postfix_evaluation(const std::int64_t *values,
                                             std::size_t length) noexcept
{
    if (length < 2 || length > 512 || length % 2 != 0) return invalid_result;
    const std::size_t token_count = length / 2;
    std::int64_t stack[256];
    std::size_t top = 0;
    for (std::size_t token = 0; token < token_count; ++token) {
        const auto opcode = values[2 * token];
        const auto operand = values[2 * token + 1];
        if (opcode == 0) {
            if (operand < -1000000 || operand > 1000000) return invalid_result;
            stack[top++] = operand;
        } else {
            if (opcode < 1 || opcode > 4 || operand != 0 || top < 2) return invalid_result;
            const auto right = stack[--top];
            const auto left = stack[--top];
            const auto result = apply(opcode, left, right);
            if (result == invalid_result) return invalid_result;
            stack[top++] = result;
        }
    }
    return top == 1 ? stack[0] : invalid_result;
}
