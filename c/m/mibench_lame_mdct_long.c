#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 18u
#define MAX_INPUT_LENGTH 19u
#define OUTPUT_COUNT 18u
#define PI 3.14159265358979323846264338327950288

int64_t mibench_lame_mdct_long(const double *input, size_t input_length,
                               double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t k = 0u; k < input_length; ++k) {
        if (!isfinite(input[k]) || input[k] < -16.0 || input[k] > 16.0) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;

    double staged[OUTPUT_COUNT];
    for (size_t m = 0u; m < OUTPUT_COUNT; ++m) {
        double sum = 0.0;
        for (size_t k = 0u; k < INPUT_COUNT; ++k) {
            const size_t offset = k < 9u ? 38u : 74u;
            const double angle = PI * (double)(2u * m + 1u) * (double)(4u * k + offset) / 144.0;
            sum += input[k] * cos(angle);
        }
        staged[m] = (4.0 / 36.0) * sum;
    }
    if (output == NULL || output_capacity < OUTPUT_COUNT) return -2;
    for (size_t m = 0u; m < OUTPUT_COUNT; ++m) output[m] = staged[m];
    return (int64_t)OUTPUT_COUNT;
}
