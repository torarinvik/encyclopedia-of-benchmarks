#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MIN_GENE INT64_C(-2147483648)
#define MAX_GENE INT64_C(2147483647)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t double_point_crossover(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 7 || length > 3 + 2 * MAX_COUNT) return -1;
    int64_t n = input[0], j1 = input[1], j2 = input[2];
    if (n < 2 || n > MAX_COUNT || length != (size_t)(3 + 2 * n) || j1 < 1 || j1 >= j2 || j2 > n) return -1;
    for (size_t i = 0; i < 2 * (size_t)n; ++i) if (input[3 + i] < MIN_GENE || input[3 + i] > MAX_GENE) return -1;
    size_t bytes = 16 * (size_t)n;
    if (output == NULL || capacity < bytes) return -2;
    size_t a = (size_t)j1, b = (size_t)j2;
    for (size_t i = 0; i < (size_t)n; ++i) {
        int64_t child1 = (i < a || i >= b) ? input[3 + i] : input[3 + (size_t)n + i];
        int64_t child2 = (i < a || i >= b) ? input[3 + (size_t)n + i] : input[3 + i];
        put_i64_le(output, i * 8, child1);
        put_i64_le(output, ((size_t)n + i) * 8, child2);
    }
    return (int64_t)bytes;
}
