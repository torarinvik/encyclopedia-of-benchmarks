/* Check (), [], and {} nesting; ignore other character codes. */
#include <stddef.h>
#include <stdint.h>

int64_t balanced_parentheses(const int64_t *values, size_t length)
{
    if (length > 4096) return -1;
    int64_t stack[4096];
    size_t top = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value == 40 || value == 91 || value == 123) {
            stack[top++] = value;
        } else if (value == 41 || value == 93 || value == 125) {
            if (top == 0) return 0;
            const int64_t opener = stack[--top];
            if ((value == 41 && opener != 40) ||
                (value == 93 && opener != 91) ||
                (value == 125 && opener != 123)) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
