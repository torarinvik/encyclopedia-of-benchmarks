#include <cstddef>
#include <cstdint>

extern "C" std::int64_t duplicate_brackets(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 1) return -1;
    const auto count = packed[0];
    if (count < 0 || count > 256 || length != static_cast<std::size_t>(count) + 1) return -1;
    std::int64_t depth = 0;
    for (std::int64_t index = 0; index < count; ++index) {
        const auto ch = packed[index + 1];
        if (ch < 32 || ch > 126) return -1;
        if (ch == '(') ++depth;
        else if (ch == ')' && --depth < 0) return -1;
    }
    if (depth != 0) return -1;
    std::int64_t stack[256];
    std::size_t top = 0;
    for (std::int64_t index = 0; index < count; ++index) {
        const auto ch = packed[index + 1];
        if (ch == ')') {
            if (top == 0 || stack[top - 1] == '(') return 1;
            while (top > 0 && stack[top - 1] != '(') --top;
            if (top > 0) --top;
        } else {
            stack[top++] = ch;
        }
    }
    return 0;
}
