#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 6
#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)

static int exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value)
        return 0;
    *decoded = (int)value;
    return 1;
}

static double sample(int function_id, double x)
{
    if (function_id == 0) return x * x * x * x;
    if (function_id == 1) return sin(x);
    return 1.0 / (1.0 + x * x);
}

static double simpson(double a, double b, double fa, double fm, double fb)
{
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0;
}

static double refine(int function_id, double a, double b, double fa, double fm, double fb,
                     double whole, double tolerance, int depth)
{
    const double middle = (a + b) * 0.5;
    const double left_middle = (a + middle) * 0.5;
    const double right_middle = (middle + b) * 0.5;
    const double flm = sample(function_id, left_middle);
    const double frm = sample(function_id, right_middle);
    const double left = simpson(a, middle, fa, flm, fm);
    const double right = simpson(middle, b, fm, frm, fb);
    const double delta = left + right - whole;
    if (depth == 0 || fabs(delta) <= 15.0 * tolerance)
        return left + right + delta / 15.0;
    return refine(function_id, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1) +
           refine(function_id, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1);
}

int64_t adaptive_simpson_quadrature(const double *input, size_t input_length,
                                    double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 5 || input_length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int function_id, a_micro, b_micro, exponent, depth;
    if (!exact_integer(input[0], 0, 2, &function_id) ||
        !exact_integer(input[1], -2000000, 2000000, &a_micro) ||
        !exact_integer(input[2], -2000000, 2000000, &b_micro) ||
        !exact_integer(input[3], 7, 8, &exponent) ||
        !exact_integer(input[4], 8, 12, &depth) || a_micro > b_micro) return INVALID_RESULT;
    if (output == NULL || output_capacity < 1) return OUTPUT_ERROR;

    const double a = (double)a_micro / 1000000.0;
    const double b = (double)b_micro / 1000000.0;
    double tolerance = 1.0;
    for (int i = 0; i < exponent; ++i) tolerance *= 0.1;
    double result = 0.0;
    if (a != b) {
        const double middle = (a + b) * 0.5;
        const double fa = sample(function_id, a);
        const double fm = sample(function_id, middle);
        const double fb = sample(function_id, b);
        result = refine(function_id, a, b, fa, fm, fb,
                        simpson(a, b, fa, fm, fb), tolerance, depth);
    }
    if (!isfinite(result)) return INVALID_RESULT;
    output[0] = result;
    return 1;
}
