#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MOMENTUM_MAX_LENGTH = 64, MOMENTUM_ITERATIONS = 100 };
static const double MOMENTUM_LEARNING_RATE = 0.01;
static const double MOMENTUM_BETA = 0.9;

int64_t momentum(const double *input, size_t length, double *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > MOMENTUM_MAX_LENGTH) return -1;
    double values[MOMENTUM_MAX_LENGTH];
    double velocity[MOMENTUM_MAX_LENGTH] = {0.0};
    double gradient[MOMENTUM_MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (!isfinite(input[index]) || input[index] < -1000000.0 || input[index] > 1000000.0) return -1;
        values[index] = input[index];
    }
    if (output == NULL || output_capacity < length) return -2;

    for (size_t iteration = 0; iteration < MOMENTUM_ITERATIONS; ++iteration) {
        for (size_t index = 0; index < length; ++index) gradient[index] = 2.0 * values[index];
        for (size_t index = 0; index < length; ++index) {
            velocity[index] = MOMENTUM_BETA * velocity[index] + gradient[index];
            values[index] -= MOMENTUM_LEARNING_RATE * velocity[index];
        }
    }
    for (size_t index = 0; index < length; ++index) output[index] = values[index];
    return (int64_t)length;
}
