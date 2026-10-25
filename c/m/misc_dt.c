#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_ITERATIONS = 128, MAX_VECTOR_SIZE = 64 };

int64_t misc_dt(const double *input, size_t input_length,
                double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 2) return -1;
    const double requested_iterations = input[0];
    const double requested_size = input[1];
    if (!(requested_iterations >= 1.0 && requested_iterations <= MAX_ITERATIONS) ||
        requested_iterations != (double)(int64_t)requested_iterations ||
        !(requested_size >= 1.0 && requested_size <= MAX_VECTOR_SIZE) ||
        requested_size != (double)(size_t)requested_size) return -1;
    const int64_t iterations = (int64_t)requested_iterations;
    const size_t size = (size_t)requested_size;
    if (output == NULL || output_capacity < size) return -2;

    double numerator[MAX_VECTOR_SIZE];
    double denominator[MAX_VECTOR_SIZE];
    for (size_t index = 0; index < size; ++index) {
        numerator[index] = 1.0000001 * (double)cosf((float)(size - index));
        denominator[index] = 1.0 + 1e-10 * (double)sinf((float)index);
    }
    for (int64_t iteration = 0; iteration < iterations; ++iteration)
        for (size_t index = 0; index < size; ++index)
            numerator[index] /= denominator[index];

    for (size_t index = 0; index < size; ++index) output[index] = numerator[index];
    return (int64_t)size;
}
