#include <stddef.h>
#include <stdint.h>

int64_t two_pointers_pair_exists(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 258) return -1;
    const int64_t target = input[0], n = input[1];
    if (n < 0 || n > 256 || length != 2 + (size_t)n || target < -2000000 || target > 2000000) return -1;
    for (size_t i = 0; i < (size_t)n; ++i) {
        const int64_t value = input[2 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (i > 0 && input[1 + i] > value) return -1;
    }
    if (n < 2) return 0;
    size_t left = 0, right = (size_t)n - 1;
    while (left < right) {
        const int64_t sum = input[2 + left] + input[2 + right];
        if (sum == target) return 1;
        if (sum < target) ++left;
        else --right;
    }
    return 0;
}
