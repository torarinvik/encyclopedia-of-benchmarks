#include <stddef.h>
#include <stdint.h>

#define MAX_Q 8
#define MAX_N INT64_C(10000)

static int64_t integer_sqrt(int64_t value) {
    int64_t low = 0;
    int64_t high = value + 1;
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

static void write_u32(uint8_t *output, size_t offset, uint32_t value) {
    output[offset] = (uint8_t)value;
    output[offset + 1] = (uint8_t)(value >> 8);
    output[offset + 2] = (uint8_t)(value >> 16);
    output[offset + 3] = (uint8_t)(value >> 24);
}

int64_t two_square_sum(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_Q + 1) return -1;
    const int64_t q64 = input[0];
    if (q64 < 1 || q64 > MAX_Q) return -1;
    const size_t q = (size_t)q64;
    if (length != q + 1) return -1;

    int64_t numbers[MAX_Q] = {0};
    size_t counts[MAX_Q] = {0};
    size_t total_pairs = 0;
    for (size_t query = 0; query < q; ++query) {
        const int64_t n = input[query + 1];
        if (n < 0 || n > MAX_N) return -1;
        numbers[query] = n;
        for (int64_t a = 0; a * a <= n; ++a) {
            const int64_t remainder = n - a * a;
            const int64_t b = integer_sqrt(remainder);
            if (b * b == remainder) ++counts[query];
        }
        total_pairs += counts[query];
    }

    const size_t required = 4 * (q + 2 * total_pairs);
    if (output == NULL || capacity < required) return -2;
    size_t offset = 0;
    for (size_t query = 0; query < q; ++query) {
        write_u32(output, offset, (uint32_t)counts[query]);
        offset += 4;
        const int64_t n = numbers[query];
        for (int64_t a = 0; a * a <= n; ++a) {
            const int64_t remainder = n - a * a;
            const int64_t b = integer_sqrt(remainder);
            if (b * b != remainder) continue;
            write_u32(output, offset, (uint32_t)a);
            write_u32(output, offset + 4, (uint32_t)b);
            offset += 8;
        }
    }
    return (int64_t)offset;
}
