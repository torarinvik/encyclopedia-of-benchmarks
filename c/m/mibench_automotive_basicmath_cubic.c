#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { CUBIC_INPUT_COUNT = 4, CUBIC_MAX_ROOTS = 3 };

static int solve_cubic(const double *input, double roots[CUBIC_MAX_ROOTS])
{
    const double a = input[0], b = input[1], c = input[2], d = input[3];
    const double a1 = b / a, a2 = c / a, a3 = d / a;
    const double q = (a1 * a1 - 3.0 * a2) / 9.0;
    const double r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0;
    const double discriminant = r * r - q * q * q;
    if (discriminant == 0.0) return -1;

    if (discriminant <= 0.0) {
        const double theta = acos(r / sqrt(q * q * q));
        roots[0] = -2.0 * sqrt(q) * cos(theta / 3.0) - a1 / 3.0;
        roots[1] = -2.0 * sqrt(q) * cos((theta + 2.0 * acos(-1.0)) / 3.0) - a1 / 3.0;
        roots[2] = -2.0 * sqrt(q) * cos((theta + 4.0 * acos(-1.0)) / 3.0) - a1 / 3.0;
        return 3;
    }

    double root = pow(sqrt(discriminant) + fabs(r), 1.0 / 3.0);
    root += q / root;
    root *= r < 0.0 ? 1.0 : -1.0;
    roots[0] = root - a1 / 3.0;
    return 1;
}

int64_t mibench_automotive_basicmath_cubic(const double *input, size_t input_length,
                                            double *output, size_t output_capacity)
{
    if (input == NULL || input_length != CUBIC_INPUT_COUNT) return -1;
    for (size_t index = 0; index < CUBIC_INPUT_COUNT; ++index)
        if (!(input[index] >= -100.0 && input[index] <= 100.0)) return -1;
    if (input[0] > -1.0 && input[0] < 1.0) return -1;

    double roots[CUBIC_MAX_ROOTS];
    const int count = solve_cubic(input, roots);
    if (count < 0) return -1;
    if (output == NULL || output_capacity < (size_t)count) return -2;
    for (int index = 0; index < count; ++index) output[index] = roots[index];
    return count;
}
