// Check (), [], and {} nesting; ignore other character codes.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t balanced_parentheses(const std::int64_t *values, std::size_t length)
{
    if (length > 4096) return -1;
    std::int64_t stack[4096];
    std::size_t top = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = values[index];
        if (value == 40 || value == 91 || value == 123) {
            stack[top++] = value;
        } else if (value == 41 || value == 93 || value == 125) {
            if (top == 0) return 0;
            const auto opener = stack[--top];
            if ((value == 41 && opener != 40) ||
                (value == 93 && opener != 91) ||
                (value == 125 && opener != 123)) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
