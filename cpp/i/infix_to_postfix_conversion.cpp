// Shunting-yard conversion with Python source precedence and associativity.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_EXPRESSION = 256;
constexpr std::size_t MAX_OUTPUT = 512;
bool is_operand(std::int64_t ch) {
    return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
}
bool is_operator(std::int64_t ch) { return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^'; }
int precedence(std::int64_t ch) { return ch == '+' || ch == '-' ? 1 : (ch == '*' || ch == '/' ? 2 : 3); }
void emit_token(std::uint8_t *result, std::size_t *count, std::uint8_t token) {
    if (*count > 0) result[(*count)++] = ' ';
    result[(*count)++] = token;
}
}

extern "C" std::int64_t infix_to_postfix_conversion(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1) return -1;
    const std::int64_t expression_length = input[0];
    if (expression_length < 0 || expression_length > static_cast<std::int64_t>(MAX_EXPRESSION) ||
        length != 1 + static_cast<std::size_t>(expression_length)) return -1;
    std::uint8_t stack[MAX_EXPRESSION], result[MAX_OUTPUT];
    std::size_t top = 0, count = 0;
    bool expect_operand = true;
    for (std::size_t i = 0; i < static_cast<std::size_t>(expression_length); ++i) {
        const std::int64_t ch = input[1 + i];
        if (is_operand(ch)) {
            if (!expect_operand) return -1;
            emit_token(result, &count, static_cast<std::uint8_t>(ch));
            expect_operand = false;
        } else if (ch == '(') {
            if (!expect_operand || top == MAX_EXPRESSION) return -1;
            stack[top++] = '(';
        } else if (ch == ')') {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(') emit_token(result, &count, stack[--top]);
            if (top == 0) return -1;
            --top;
            expect_operand = false;
        } else if (is_operator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' &&
                   (precedence(ch) < precedence(stack[top - 1]) ||
                    (precedence(ch) == precedence(stack[top - 1]) && ch != '^'))) {
                emit_token(result, &count, stack[--top]);
            }
            if (top == MAX_EXPRESSION) return -1;
            stack[top++] = static_cast<std::uint8_t>(ch);
            expect_operand = true;
        } else return -1;
    }
    if (expression_length != 0 && expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        emit_token(result, &count, stack[--top]);
    }
    result[count++] = 0;
    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(count);
}
