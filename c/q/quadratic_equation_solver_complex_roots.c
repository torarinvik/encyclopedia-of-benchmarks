/* Select one real or imaginary component from the Java quadratic solver. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define COEFFICIENT_LIMIT INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double quadratic_equation_solver_complex_roots(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t a = values[0], b = values[1], c = values[2], component = values[3];
    if (a == 0 || a < -COEFFICIENT_LIMIT || a > COEFFICIENT_LIMIT ||
        b < -COEFFICIENT_LIMIT || b > COEFFICIENT_LIMIT ||
        c < -COEFFICIENT_LIMIT || c > COEFFICIENT_LIMIT ||
        component < 0 || component > 3) return INVALID_RESULT;

    const int64_t discriminant = b * b - 4 * a * c;
    const double denominator = 2.0 * (double)a;
    if (discriminant > 0) {
        if (component >= 2) return INVALID_RESULT;
        const double square_root = sqrt((double)discriminant);
        return component == 0 ? (-(double)b + square_root) / denominator
                              : (-(double)b - square_root) / denominator;
    }
    if (discriminant == 0) {
        return component == 0 ? -(double)b / denominator : INVALID_RESULT;
    }

    if (component < 2) return -(double)b / denominator;
    const double imaginary = sqrt((double)(-discriminant)) / denominator;
    return component == 2 ? imaginary : -imaginary;
}
