#include <stddef.h>
#include <stdint.h>
#define MAX_BITS 256
int64_t unbias_01(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > MAX_BITS + 1) return -1;
    int64_t n = input[0];
    if (n < 0 || n > MAX_BITS || length != (size_t)n + 1) return -1;
    for (size_t i = 0; i < (size_t)n; ++i) if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
    for (size_t i = 0; i + 1 < (size_t)n; i += 2) if (input[i + 1] != input[i + 2]) return input[i + 1];
    return -1;
}
