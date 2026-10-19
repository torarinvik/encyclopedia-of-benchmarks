#include <stddef.h>
#include <stdint.h>

enum { MAX_ITERATIONS = 256, VECTOR_LENGTH = 2048 };

int64_t misc_fp_convert(const double *input, size_t input_length,
                        double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 1) return -1;
    const double requested = input[0];
    if (!(requested >= 1.0 && requested <= MAX_ITERATIONS) ||
        requested != (double)(int64_t)requested) return -1;
    if (output == NULL || output_capacity < 1) return -2;

    const int64_t iterations = (int64_t)requested;
    float x[VECTOR_LENGTH];
    float y[VECTOR_LENGTH];
    float a = 0.0f;
    float b = 1.0f;
    double total = 0.0;
    for (int64_t iteration = 0; iteration < iterations; ++iteration) {
        if (iteration % 10 != 0) {
            a = 0.0f;
            b = 1.0f;
        } else {
            a += 0.1f;
            b += 0.2f;
        }
        for (size_t index = 0; index < VECTOR_LENGTH; ++index) {
            x[index] = a + (float)index;
            y[index] = b + (float)index;
        }
        double accumulator = 0.0;
        for (size_t index = 0; index < VECTOR_LENGTH; ++index)
            accumulator += (double)x[index] * (double)y[index];
        total += accumulator;
    }
    output[0] = total;
    return 1;
}
