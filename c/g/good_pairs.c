#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(256)
#define VALUE_LIMIT INT64_C(1000000)

int64_t good_pairs(const int64_t *packed, size_t length) {
    if (packed == NULL || length < 1 || length > 257) return -1;
    const int64_t n = packed[0];
    if (n < 0 || n > MAX_N || length != (size_t)n + 1) return -1;
    for (int64_t i = 0; i < n; ++i)
        if (packed[1 + (size_t)i] < -VALUE_LIMIT || packed[1 + (size_t)i] > VALUE_LIMIT) return -1;
    int64_t count = 0;
    for (int64_t i = 0; i < n; ++i)
        for (int64_t j = i + 1; j < n; ++j)
            if (packed[1 + (size_t)i] == packed[1 + (size_t)j]) ++count;
    return count;
}
