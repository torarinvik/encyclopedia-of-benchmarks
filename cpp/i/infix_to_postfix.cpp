/* Convert a bounded ASCII infix expression with the source's operator stack. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxExpression = 24, kMaxStack = 10;
bool operand(std::int64_t c) noexcept {
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
bool operation(std::int64_t c) noexcept { return c == '+' || c == '-' || c == '*' || c == '/' || c == '^'; }
int precedence(std::int64_t c) noexcept { return c == '+' || c == '-' ? 1 : (c == '*' || c == '/' ? 2 : 3); }
}

extern "C" std::int64_t infix_to_postfix(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length == 0 || length > kMaxExpression) return -1;
    std::uint8_t stack[kMaxStack], result[kMaxExpression + 1];
    std::size_t top = 0, count = 0;
    bool expect_operand = true;
    for (std::size_t i = 0; i < length; ++i) {
        const auto ch = input[i];
        if (operand(ch)) {
            if (!expect_operand) return -1;
            result[count++] = static_cast<std::uint8_t>(ch);
            expect_operand = false;
        } else if (ch == '(') {
            if (!expect_operand || top == kMaxStack) return -1;
            stack[top++] = static_cast<std::uint8_t>(ch);
        } else if (ch == ')') {
            while (top > 0 && stack[top - 1] != '(') result[count++] = stack[--top];
            if (top > 0) --top;
            expect_operand = false;
        } else if (operation(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' && precedence(ch) <= precedence(stack[top - 1]))
                result[count++] = stack[--top];
            if (top == kMaxStack) return -1;
            stack[top++] = static_cast<std::uint8_t>(ch);
            expect_operand = true;
        } else return -1;
    }
    if (expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        result[count++] = stack[--top];
    }
    result[count++] = 0;
    if (output == nullptr || capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(count);
}
