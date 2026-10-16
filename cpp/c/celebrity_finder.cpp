#include <cstddef>
#include <cstdint>

extern "C" int64_t celebrity_finder(const int64_t *input, size_t length) {
    if (!input || length < 2 || input[0] < 1 || input[0] > 64) return -2;
    const size_t n = static_cast<size_t>(input[0]);
    if (length != 1 + n * n) return -2;
    for (size_t i = 1; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -2;
    int stack[64];
    size_t top = 0;
    for (size_t i = 0; i < n; ++i) stack[top++] = static_cast<int>(i);
    while (top > 1) {
        const int person1 = stack[--top];
        const int person2 = stack[--top];
        stack[top++] = input[1 + static_cast<size_t>(person1) * n + static_cast<size_t>(person2)] == 1 ? person2 : person1;
    }
    const int candidate = stack[0];
    for (size_t i = 0; i < n; ++i) {
        if (static_cast<int>(i) != candidate &&
            (input[1 + static_cast<size_t>(candidate) * n + i] == 1 || input[1 + i * n + static_cast<size_t>(candidate)] == 0)) return -1;
    }
    return candidate;
}
