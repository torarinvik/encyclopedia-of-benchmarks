#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_ENDPOINT_MILLI 100000

static double equation(double x)
{
    return 10.0 - x * x;
}

double bisection_2(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return INVALID_RESULT;
    const int64_t left_milli = input[0], right_milli = input[1];
    if (left_milli < -MAX_ENDPOINT_MILLI || left_milli > MAX_ENDPOINT_MILLI
        || right_milli < -MAX_ENDPOINT_MILLI || right_milli > MAX_ENDPOINT_MILLI
        || left_milli >= right_milli) return INVALID_RESULT;
    double a = (double)left_milli / 1000.0;
    double b = (double)right_milli / 1000.0;
    if (equation(a) * equation(b) >= 0.0) return INVALID_RESULT;
    double c = a;
    while ((b - a) >= 0.01) {
        c = (a + b) / 2.0;
        if (equation(c) == 0.0) break;
        if (equation(c) * equation(a) < 0.0) b = c;
        else a = c;
    }
    return c;
}
