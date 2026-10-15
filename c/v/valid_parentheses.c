#include <stddef.h>
#include <stdint.h>

int64_t valid_parentheses(const int64_t *input, size_t length) {
    if (length > 256 || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (value != 40 && value != 41 && value != 91 && value != 93 && value != 123 && value != 125)
            return -1;
    }
    uint8_t stack[256];
    size_t top = 0;
    for (size_t index = 0; index < length; ++index) {
        const uint8_t value = (uint8_t)input[index];
        if (value == '(' || value == '[' || value == '{') stack[top++] = value;
        else {
            if (top == 0) return 0;
            const uint8_t expected = value == ')' ? '(' : value == ']' ? '[' : '{';
            if (stack[--top] != expected) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
