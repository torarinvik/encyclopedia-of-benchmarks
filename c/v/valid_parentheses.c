#include <stddef.h>
#include <stdint.h>

static uint8_t bracket_closer(int64_t value)
{
    switch (value) {
        case '(': return ')';
        case '[': return ']';
        case '{': return '}';
        case ')': case ']': case '}': return 0;
        default: return UINT8_MAX;
    }
}

static int64_t invalid_suffix(const int64_t *input, size_t start, size_t length)
{
    for (size_t index = start; index < length; ++index)
        if (bracket_closer(input[index]) == UINT8_MAX) return -1;
    return 0;
}

static int64_t check_brackets(const int64_t *input, size_t length, uint8_t *pending)
{
    size_t top = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        const uint8_t closer = bracket_closer(value);
        if (closer == UINT8_MAX) return -1;
        if (closer != 0) {
            if (top >= length / 2) return invalid_suffix(input, index + 1, length);
            pending[top++] = closer;
        } else {
            if (top == 0 || pending[--top] != value)
                return invalid_suffix(input, index + 1, length);
        }
    }
    return top == 0 ? 1 : 0;
}

int64_t valid_parentheses(const int64_t *input, size_t length)
{
    if (length > 256 || (length != 0 && input == NULL)) return -1;
    if (length == 0) return 1;
    if (length & 1) return invalid_suffix(input, 0, length);
    if (length <= 32) {
        uint8_t pending[16];
        return check_brackets(input, length, pending);
    }
    uint8_t pending[128];
    return check_brackets(input, length, pending);
}
