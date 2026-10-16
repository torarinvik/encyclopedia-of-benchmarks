/* Portable fixed-point port of TheAlgorithms/Python's Barnsley fern maps. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITERATIONS 4096
#define Q12 INT64_C(1000000000000)
#define Q12_OFFSET INT64_C(10000000000)
#define Q6_DIVISOR INT64_C(1000000)

static const int coefficients[4][6] = {
    {0, 0, 0, 16, 0, 0},
    {85, 4, -4, 85, 0, 160},
    {20, -26, 23, 22, 0, 160},
    {-15, 28, 26, 24, 0, 44},
};

static int64_t round_div_even(int64_t numerator, int64_t denominator) {
    int negative = numerator < 0;
    uint64_t magnitude = (uint64_t)(negative ? -numerator : numerator);
    uint64_t divisor = (uint64_t)denominator;
    uint64_t quotient = magnitude / divisor;
    uint64_t remainder = magnitude % divisor;
    if (remainder * 2 > divisor || (remainder * 2 == divisor && (quotient & 1u))) ++quotient;
    return negative ? -(int64_t)quotient : (int64_t)quotient;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t barnsley_fern(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    int64_t iteration_value = input[0];
    if (iteration_value < 1 || iteration_value > MAX_ITERATIONS || length != (size_t)iteration_value)
        return -1;
    size_t iterations = (size_t)iteration_value;
    for (size_t step = 1; step < iterations; ++step)
        if (input[step] < 0 || input[step] >= 10000) return -1;
    size_t output_length = iterations * 16;
    if (output == NULL || capacity < output_length) return -2;

    int64_t x = 0, y = 0;
    put_i64_le(output, 0, 0);
    put_i64_le(output, 8, 0);
    for (size_t step = 1; step < iterations; ++step) {
        int64_t sample = input[step];
        size_t transform = sample < 100 ? 0 : sample < 8600 ? 1 : sample < 9300 ? 2 : 3;
        const int *map = coefficients[transform];
        int64_t next_x = round_div_even((int64_t)map[0] * x + (int64_t)map[1] * y, 100)
                       + (int64_t)map[4] * Q12_OFFSET;
        int64_t next_y = round_div_even((int64_t)map[2] * x + (int64_t)map[3] * y, 100)
                       + (int64_t)map[5] * Q12_OFFSET;
        x = next_x;
        y = next_y;
        put_i64_le(output, step * 16, round_div_even(x, Q6_DIVISOR));
        put_i64_le(output, step * 16 + 8, round_div_even(y, Q6_DIVISOR));
    }
    return (int64_t)output_length;
}
