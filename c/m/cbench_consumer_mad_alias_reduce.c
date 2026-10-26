#include <stddef.h>
#include <stdint.h>

enum { MAX_BOUNDARIES = 4, VALUES_PER_BOUNDARY = 16, MAX_INPUT_LENGTH = 65,
       MAX_OUTPUT_BYTES = 256 };

static const int64_t CS[8] = {
    0x0db84a81LL, 0x0e1b9d7fLL, 0x0f31adcfLL, 0x0fbba815LL,
    0x0feda417LL, 0x0ffc8fc8LL, 0x0fff964cLL, 0x0ffff8d3LL
};
static const int64_t CA[8] = {
    -0x083b5fe7LL, -0x078c36d2LL, -0x05039814LL, -0x02e91dd1LL,
    -0x0183603aLL, -0x00a7cb87LL, -0x003a2847LL, -0x000f27b4LL
};

static int64_t floor_div(int64_t value, int64_t divisor)
{
    int64_t quotient = value / divisor;
    if (value % divisor < 0) --quotient;
    return quotient;
}

/* FPM_DEFAULT mad_f_mul: two pre-rounded shifts, then an integer product. */
static int64_t mad_mul(int64_t left, int64_t right)
{
    return floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536);
}

int64_t cbench_consumer_mad_alias_reduce(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_BOUNDARIES) return -1;
    const size_t boundaries = (size_t)input[0];
    if (length != 1u + VALUES_PER_BOUNDARY * boundaries) return -1;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < -100000000LL || input[i] > 100000000LL) return -1;

    const size_t output_size = 64u * boundaries;
    int32_t transformed[MAX_BOUNDARIES * VALUES_PER_BOUNDARY];
    for (size_t boundary = 0; boundary < boundaries; ++boundary) {
        const size_t base = 1u + VALUES_PER_BOUNDARY * boundary;
        for (size_t i = 0; i < 8; ++i) {
            const int64_t a = input[base + 2u * i];
            const int64_t b = input[base + 2u * i + 1u];
            transformed[base - 1u + 2u * i] = (int32_t)(mad_mul(a, CS[i]) + mad_mul(-b, CA[i]));
            transformed[base - 1u + 2u * i + 1u] = (int32_t)(mad_mul(b, CS[i]) + mad_mul(a, CA[i]));
        }
    }
    if (output == NULL || capacity < output_size) return -2;
    for (size_t i = 0; i < VALUES_PER_BOUNDARY * boundaries; ++i) {
        const uint32_t value = (uint32_t)transformed[i];
        output[4u * i] = (uint8_t)value;
        output[4u * i + 1u] = (uint8_t)(value >> 8);
        output[4u * i + 2u] = (uint8_t)(value >> 16);
        output[4u * i + 3u] = (uint8_t)(value >> 24);
    }
    return (int64_t)output_size;
}
