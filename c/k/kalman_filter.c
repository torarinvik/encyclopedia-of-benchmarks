#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 12
#define MAX_PARSEABLE_LENGTH 64
#define SCALE 1000000.0

int64_t kalman_filter(const double *input, size_t length,
                      double *output, size_t output_capacity)
{
    if (input == NULL || length < 5 || length > MAX_PARSEABLE_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (!isfinite(input[index]) || trunc(input[index]) != input[index]) return -1;
    }
    const double raw_steps = input[4];
    if (raw_steps < 1.0 || raw_steps > MAX_STEPS) return -1;
    const size_t steps = (size_t)raw_steps;
    if (length != 5 + steps) return -1;
    if (input[0] < -1000000000.0 || input[0] > 1000000000.0 ||
        input[1] < 0.0 || input[1] > 1000000000000.0 ||
        input[2] < 0.0 || input[2] > 1000000000000.0 ||
        input[3] < 1.0 || input[3] > 1000000000000.0) return -1;
    for (size_t index = 0; index < steps; ++index) {
        const double measurement = input[5 + index];
        if (measurement < -1000000000.0 || measurement > 1000000000.0) return -1;
    }

    const size_t required = 3 * steps;
    if (output == NULL || output_capacity < required) return -2;

    double estimate = input[0] / SCALE;
    double covariance = input[1] / SCALE;
    const double process_noise = input[2] / SCALE;
    const double measurement_noise = input[3] / SCALE;
    for (size_t step = 0; step < steps; ++step) {
        const double measurement = input[5 + step] / SCALE;
        estimate += 0.0;
        covariance += process_noise;
        const double innovation_variance = covariance + measurement_noise;
        const double gain = covariance / innovation_variance;
        estimate += gain * (measurement - estimate);
        covariance = covariance * measurement_noise / innovation_variance;
        output[3 * step] = estimate;
        output[3 * step + 1] = covariance;
        output[3 * step + 2] = gain;
    }
    return (int64_t)required;
}
