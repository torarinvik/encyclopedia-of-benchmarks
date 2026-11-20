/* Bounded Takahasi-Mori tanh-sinh quadrature on [-1,1]. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 3
#define PI 3.14159265358979323846264338327950288

static int exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static double integrate(int function_id, int p)
{
    const double h = 1.0 / (double)(1 << p);
    const double half_pi = PI / 2.0;
    const int limit = 3 * (1 << p);
    double total = 0.0;
    for (int j = -limit; j <= limit; ++j) {
        const double t = (double)j * h;
        const double exp_t = exp(t);
        const double exp_minus_t = exp(-t);
        const double sinh_t = (exp_t - exp_minus_t) * 0.5;
        const double cosh_t = (exp_t + exp_minus_t) * 0.5;
        const double u = half_pi * sinh_t;
        const double abs_u = u < 0.0 ? -u : u;
        const double q = exp(-2.0 * abs_u);
        const double one_plus_q = 1.0 + q;
        const double sech_squared = (4.0 * q) / (one_plus_q * one_plus_q);
        const double magnitude_x = (1.0 - q) / one_plus_q;
        const double x = u >= 0.0 ? magnitude_x : -magnitude_x;
        const double jacobian = (half_pi * cosh_t) * sech_squared;
        double sample;
        if (function_id == 0) sample = 1.0;
        else if (function_id == 1) sample = x * x;
        else if (function_id == 2) sample = 1.0 / sqrt(sech_squared);
        else if (u >= 0.0) sample = 1.0 / sqrt((2.0 * q) / one_plus_q);
        else sample = 1.0 / sqrt(2.0 / one_plus_q);
        const double transformed = sample * jacobian;
        total += h * transformed;
    }
    return total;
}

int64_t tanh_sinh_double_exponential_quadrature(const double *input, size_t input_length,
                                                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int function_id, p;
    if (input_length != 2 || !exact_integer(input[0], 0, 3, &function_id)
        || !exact_integer(input[1], 2, 4, &p)) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    const double value = integrate(function_id, p);
    if (!isfinite(value)) return -1;
    output[0] = value;
    return 1;
}
