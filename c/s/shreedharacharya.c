#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COEFFICIENT 1000000.0
#define MIN_ABS_LEADING_COEFFICIENT 0.000001

int64_t shreedharacharya(const double *input, size_t input_length,
                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 3) return -1;
    const double a = input[0], b = input[1], c = input[2];
    if (!isfinite(a) || !isfinite(b) || !isfinite(c) ||
        fabs(a) < MIN_ABS_LEADING_COEFFICIENT || fabs(a) > MAX_COEFFICIENT ||
        fabs(b) > MAX_COEFFICIENT || fabs(c) > MAX_COEFFICIENT) return -1;

    const double discriminant = b * b - 4.0 * a * c;
    double roots[2];
    size_t count = 0;
    if (discriminant == 0.0) {
        roots[count++] = -b / (2.0 * a);
    } else if (discriminant > 0.0) {
        const double square_root = sqrt(discriminant);
        const double denominator = 2.0 * a;
        roots[count++] = (-b + square_root) / denominator;
        roots[count++] = (-b - square_root) / denominator;
    }
    for (size_t index = 0; index < count; ++index)
        if (!isfinite(roots[index])) return -1;
    if (output == NULL || output_capacity < count) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = roots[index];
    return (int64_t)count;
}
