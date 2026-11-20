#include <stddef.h>
#include <stdint.h>

#define MIN_WORDS 7u
#define MAX_WORDS 17u
#define OUTPUT_BYTES 16u

static int64_t weniger_gcd(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static void weniger_store_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t weniger_pochhammer_partial_sum_transform(
    const int64_t *input, size_t input_length,
    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < MIN_WORDS || input_length > MAX_WORDS) return -1;
    const int64_t n0 = input[0], k0 = input[1];
    if (n0 < 0 || n0 > 8 || k0 < 3 || k0 > 4) return -1;
    const size_t n = (size_t)n0, k = (size_t)k0;
    if (input_length != n + k + 4) return -1;
    const size_t term_count = n + k + 2;
    for (size_t i = 0; i < term_count; ++i)
        if (input[i + 2] == 0 || input[i + 2] < -3 || input[i + 2] > 3) return -1;

    int64_t product = 1;
    for (size_t r = 0; r <= k; ++r) product *= input[n + r + 3];
    int64_t numerator = 0, denominator = 0;
    for (size_t j = 0; j <= k; ++j) {
        int64_t choose = 1;
        for (size_t r = 1; r <= j; ++r)
            choose = choose * (int64_t)(k - r + 1) / (int64_t)r;
        int64_t rising = 1;
        for (size_t offset = 0; offset < k - 1; ++offset)
            rising *= (int64_t)(n + j + 1 + offset);
        const int64_t term = input[n + j + 3];
        int64_t weight = choose * rising * (product / term);
        if (j & 1u) weight = -weight;
        int64_t partial = 0;
        for (size_t index = 0; index <= n + j; ++index) partial += input[index + 2];
        numerator += weight * partial;
        denominator += weight;
    }
    if (denominator == 0) return -1;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    const int64_t divisor = weniger_gcd(numerator < 0 ? -numerator : numerator, denominator);
    numerator /= divisor;
    denominator /= divisor;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    weniger_store_i64(output, 0, numerator);
    weniger_store_i64(output, 8, denominator);
    return OUTPUT_BYTES;
}
