#include <cstddef>
#include <cstdint>

extern "C" std::int64_t valid_parentheses(const std::int64_t *input, std::size_t length) {
    if (length > 256 || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = input[index];
        if (value != 40 && value != 41 && value != 91 && value != 93 && value != 123 && value != 125)
            return -1;
    }
    std::uint8_t stack[256];
    std::size_t top = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = static_cast<std::uint8_t>(input[index]);
        if (value == '(' || value == '[' || value == '{') stack[top++] = value;
        else {
            if (top == 0) return 0;
            const auto expected = value == ')' ? '(' : value == ']' ? '[' : '{';
            if (stack[--top] != expected) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
