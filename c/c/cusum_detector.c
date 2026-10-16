/* Two-sided CUSUM detector over a bounded integer-valued input domain. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
static void put_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}
int64_t cusum_detector(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 5 || input[0] < 0 || input[0] > MAX_N) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 5) return -1;
    int64_t target = input[1], sigma = input[2], allowance = input[3], threshold = input[4];
    if (target < -1000 || target > 1000 || sigma < 1 || sigma > 1000 || allowance < 0 || allowance > 1000 || threshold < 1 || threshold > 1000) return -1;
    for (size_t i = 0; i < n; ++i) if (input[5+i] < -1000 || input[5+i] > 1000) return -1;
    if (capacity < n * 8 || (n > 0 && !output)) return -2;
    double upper = 0.0, lower = 0.0;
    for (size_t i = 0; i < n; ++i) {
        double z = ((double)input[5+i] - (double)target) / (double)sigma;
        upper = upper + z - (double)allowance;
        if (upper < 0.0) upper = 0.0;
        lower = lower - z - (double)allowance;
        if (lower < 0.0) lower = 0.0;
        int64_t signal = 0;
        if (upper > (double)threshold) signal = 1;
        else if (lower > (double)threshold) signal = -1;
        if (signal != 0) upper = lower = 0.0;
        put_i64_le(output, i * 8, signal);
    }
    return (int64_t)(n * 8);
}
