/* Bounded Clenshaw-Curtis quadrature on supplied Lobatto-node samples. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 19
#define PI 3.14159265358979323846264338327950288

static int exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static double compute(int n, const double *samples)
{
    double result = 0.0;
    for (int k = 0; k <= n; ++k) {
        double inner = 0.0;
        for (int j = 1; j <= n / 2; ++j) {
            const double bj = (j == n / 2) ? 1.0 : 2.0;
            const double denominator = (double)(4 * j * j - 1);
            const double angle = (((2.0 * (double)j) * (double)k) * PI) / (double)n;
            const double term = (bj / denominator) * cos(angle);
            inner += term;
        }
        const double gk = (k == 0 || k == n) ? 1.0 : 2.0;
        const double weight = (gk / (double)n) * (1.0 - inner);
        result += weight * samples[k];
    }
    return result;
}

int64_t clenshaw_curtis_quadrature(const double *input, size_t input_length,
                                  double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int n;
    if (!exact_integer(input[0], 2, 16, &n) || (n & 1) != 0 || input_length != (size_t)n + 2) return -1;
    for (size_t i = 1; i < input_length; ++i)
        if (!isfinite(input[i]) || fabs(input[i]) > 1000.0) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    const double result = compute(n, input + 1);
    if (!isfinite(result)) return -1;
    output[0] = result;
    return 1;
}
