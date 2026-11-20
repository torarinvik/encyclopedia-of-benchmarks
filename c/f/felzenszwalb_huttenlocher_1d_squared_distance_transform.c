#include <stddef.h>
#include <stdint.h>

enum { MAX_SITES = 128, MAX_INPUT_WORDS = 130 };

static int64_t floor_div(int64_t numerator, int64_t denominator) {
    int64_t quotient = numerator / denominator;
    const int64_t remainder = numerator % denominator;
    if (remainder != 0 && numerator < 0) --quotient;
    return quotient;
}

static void store_i64_le(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    const size_t offset = word * 8;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t felzenszwalb_huttenlocher_1d_squared_distance_transform(
    const int64_t *input, size_t length, uint8_t *output,
    size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_SITES) return -1;
    const size_t n = (size_t)n64;
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] > INT64_C(1000000)) return -1;
    if (output == NULL || output_capacity < n * 16) return -2;

    size_t sites[MAX_SITES];
    int64_t starts[MAX_SITES];
    size_t top = 0;
    sites[0] = 0;
    starts[0] = INT64_MIN / 2;
    for (size_t q = 1; q < n; ++q) {
        for (;;) {
            const size_t p = sites[top];
            const int64_t numerator = input[q + 1] + (int64_t)(q * q)
                - input[p + 1] - (int64_t)(p * p);
            const int64_t denominator = (int64_t)(2 * (q - p));
            const int64_t first = floor_div(numerator, denominator) + 1;
            if (top == 0 || first > starts[top]) {
                ++top;
                sites[top] = q;
                starts[top] = first;
                break;
            }
            --top;
        }
    }

    size_t active = 0;
    for (size_t x = 0; x < n; ++x) {
        while (active < top && starts[active + 1] <= (int64_t)x) ++active;
        const size_t site = sites[active];
        const int64_t delta = (int64_t)x - (int64_t)site;
        const int64_t distance = delta * delta + input[site + 1];
        store_i64_le(output, 2 * x, distance);
        store_i64_le(output, 2 * x + 1, (int64_t)site);
    }
    return (int64_t)(n * 16);
}
