#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 18u
#define MAX_INPUT_LENGTH 19u
#define OUTPUT_COUNT 36u
#define PI 3.14159265358979323846264338327950288

int64_t cbench_consumer_mad_imdct36(const double *input, size_t input_length,
                                    double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t k = 0u; k < input_length; ++k) {
        if (!isfinite(input[k]) || input[k] < -16.0 || input[k] > 16.0) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;

    double staged[OUTPUT_COUNT];
    for (size_t n = 0u; n < OUTPUT_COUNT; ++n) {
        double sum = 0.0;
        for (size_t k = 0u; k < INPUT_COUNT; ++k) {
            const double angle = PI * (double)(2u * n + 19u) * (double)(2u * k + 1u) / 72.0;
            sum += input[k] * cos(angle);
        }
        staged[n] = sum;
    }
    if (output == NULL || output_capacity < OUTPUT_COUNT) return -2;
    for (size_t n = 0u; n < OUTPUT_COUNT; ++n) output[n] = staged[n];
    return (int64_t)OUTPUT_COUNT;
}
