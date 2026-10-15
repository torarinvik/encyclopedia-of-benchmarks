/* Numeric first-law operations over a bounded integer-valued domain. */
#include <math.h>

#define INVALID_RESULT (-1e300)

double first_law_of_thermodynamics(double operation, double a, double b)
{
    if (!isfinite(operation) || !isfinite(a) || !isfinite(b) ||
        operation < 0.0 || operation > 2.0 || operation != trunc(operation) ||
        a < -1000000.0 || a > 1000000.0 || b < -1000000.0 || b > 1000000.0 ||
        a != trunc(a) || b != trunc(b)) return INVALID_RESULT;
    if (operation == 0.0) return a - b;
    if (operation == 1.0) return a + b;
    return a - b;
}
