/* Find a root of one of two documented cubics by interval bisection. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COORD_MILLI INT64_C(100000)
#define MAX_TOLERANCE_MICRO INT64_C(1000000)
#define ROOT_SCALE 1000000.0
#define MAX_ITERATIONS 64

static double evaluate(int64_t equation, double x)
{
    if (equation == 0) return x * x * x + 2.0 * x - 10.0;
    return x * x * x - 4.0 * x - 9.0;
}

int64_t bisection_method(const int64_t *input, size_t length)
{
    if (input == NULL || length != 4) return -1;
    const int64_t equation = input[0], left_milli = input[1];
    const int64_t right_milli = input[2], tolerance_micro = input[3];
    if (equation < 0 || equation > 1 || left_milli < -MAX_COORD_MILLI || left_milli > MAX_COORD_MILLI ||
        right_milli < -MAX_COORD_MILLI || right_milli > MAX_COORD_MILLI || left_milli >= right_milli ||
        tolerance_micro < 1 || tolerance_micro > MAX_TOLERANCE_MICRO) return -1;

    double left = (double)left_milli / 1000.0;
    double right = (double)right_milli / 1000.0;
    double f_left = evaluate(equation, left);
    double f_right = evaluate(equation, right);
    if (f_left == 0.0) return (int64_t)(left * ROOT_SCALE + 0.5);
    if (f_right == 0.0) return (int64_t)(right * ROOT_SCALE + 0.5);
    if ((f_left < 0.0) == (f_right < 0.0)) return -2;

    const double tolerance = (double)tolerance_micro / ROOT_SCALE;
    for (int iteration = 0; iteration < MAX_ITERATIONS; ++iteration) {
        const double middle = left + (right - left) * 0.5;
        const double f_middle = evaluate(equation, middle);
        if (f_middle == 0.0) return (int64_t)(middle * ROOT_SCALE + 0.5);
        if ((f_left < 0.0) != (f_middle < 0.0)) {
            right = middle;
            f_right = f_middle;
        } else {
            left = middle;
            f_left = f_middle;
        }
        if (right - left <= tolerance) {
            const double root = left + (right - left) * 0.5;
            return (int64_t)(root * ROOT_SCALE + 0.5);
        }
    }
    return -2;
}
