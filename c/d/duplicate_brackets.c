#include <stddef.h>
#include <stdint.h>

int64_t duplicate_brackets(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1) return -1;
    const int64_t count = packed[0];
    if (count < 0 || count > 256 || length != (size_t)count + 1) return -1;
    int64_t depth = 0;
    for (int64_t i = 0; i < count; ++i) {
        const int64_t ch = packed[i + 1];
        if (ch < 32 || ch > 126) return -1;
        if (ch == '(') ++depth;
        else if (ch == ')' && --depth < 0) return -1;
    }
    if (depth != 0) return -1;
    int64_t stack[256];
    size_t top = 0;
    for (int64_t i = 0; i < count; ++i) {
        const int64_t ch = packed[i + 1];
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
