#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 4096
#define MAX_DISTINCT_FACTORS 5

static int is_prime_by_source_trial_division(int64_t candidate)
{
    if (candidate == 2) return 1;
    const int64_t half_candidate = candidate / 2 + 1;
    for (int64_t divisor = 2; divisor <= half_candidate; ++divisor) {
        if (candidate % divisor == 0) return 0;
        if (divisor == half_candidate) return 1;
    }
    return 0;
}

int64_t prime_factorial(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 2 || value > MAX_INPUT) return -1;
    uint32_t factors[MAX_DISTINCT_FACTORS];
    size_t count = 0;
    for (int64_t candidate = 2; candidate <= value; ++candidate) {
        if (is_prime_by_source_trial_division(candidate) && value % candidate == 0) {
            factors[count++] = (uint32_t)candidate;
        }
    }
    const size_t required = count * sizeof(uint32_t);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (size_t index = 0; index < count; ++index) {
        const uint32_t factor = factors[index];
        for (unsigned byte_index = 0; byte_index < 4; ++byte_index) {
            output[position++] = (uint8_t)(factor >> (8 * byte_index));
        }
    }
    return (int64_t)position;
}
