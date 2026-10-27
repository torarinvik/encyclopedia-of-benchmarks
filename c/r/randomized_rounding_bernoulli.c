#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_INPUT 65

int64_t randomized_rounding_bernoulli(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != 1 + 4 * (size_t)n64) return -1;
    size_t n = (size_t)n64;
    uint8_t staged[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        int64_t x_num = input[1 + 4*i], x_den = input[2 + 4*i];
        int64_t u_num = input[3 + 4*i], u_den = input[4 + 4*i];
        if (x_den < 1 || x_den > 32 || x_num < 0 || x_num > x_den ||
            u_den < 1 || u_den > 32 || u_num < 0 || u_num >= u_den) return -1;
        staged[i] = (uint8_t)(u_num * x_den < x_num * u_den);
    }
    if (!output || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = staged[i];
    return (int64_t)n;
}
