#include <stddef.h>
#include <stdint.h>

#define MAX_PEOPLE 64

int64_t celebrity_finder(const int64_t *input, size_t length) {
    if (!input || length < 2 || input[0] < 1 || input[0] > MAX_PEOPLE) return -2;
    size_t n = (size_t)input[0];
    if (length != 1 + n * n) return -2;
    for (size_t i = 1; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -2;
    int stack[MAX_PEOPLE];
    size_t top = 0;
    for (size_t i = 0; i < n; ++i) stack[top++] = (int)i;
    while (top > 1) {
        int person1 = stack[--top];
        int person2 = stack[--top];
        stack[top++] = input[1 + (size_t)person1 * n + (size_t)person2] == 1 ? person2 : person1;
    }
    int candidate = stack[0];
    for (size_t i = 0; i < n; ++i) {
        if ((int)i == candidate) continue;
        if (input[1 + (size_t)candidate * n + i] == 1 || input[1 + i * n + (size_t)candidate] == 0) return -1;
    }
    return candidate;
}
