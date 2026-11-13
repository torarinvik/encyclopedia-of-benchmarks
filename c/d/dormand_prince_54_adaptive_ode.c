#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 7

static int integer_field(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < low || value > high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static double rhs(int id, double x, double y)
{
    switch (id) {
    case 0: return y;
    case 1: return x + y;
    case 2: return sin(x);
    default: return 1.0;
    }
}

static int trial(int id, double x, double y, double h, double k1,
                 double *y5, double *error, double *k7)
{
    const double k2 = rhs(id, x + h * (1.0/5.0),
        y + h * ((1.0/5.0) * k1));
    const double k3 = rhs(id, x + h * (3.0/10.0),
        y + h * ((3.0/40.0) * k1 + (9.0/40.0) * k2));
    const double k4 = rhs(id, x + h * (4.0/5.0),
        y + h * ((44.0/45.0) * k1 - (56.0/15.0) * k2 + (32.0/9.0) * k3));
    const double k5 = rhs(id, x + h * (8.0/9.0),
        y + h * ((19372.0/6561.0) * k1 - (25360.0/2187.0) * k2
                 + (64448.0/6561.0) * k3 - (212.0/729.0) * k4));
    const double k6 = rhs(id, x + h,
        y + h * ((9017.0/3168.0) * k1 - (355.0/33.0) * k2
                 + (46732.0/5247.0) * k3 + (49.0/176.0) * k4
                 - (5103.0/18656.0) * k5));
    *y5 = y + h * ((35.0/384.0) * k1 + (500.0/1113.0) * k3
                 + (125.0/192.0) * k4 - (2187.0/6784.0) * k5
                 + (11.0/84.0) * k6);
    *k7 = rhs(id, x + h, *y5);
    *error = h * ((71.0/57600.0) * k1 - (71.0/16695.0) * k3
                + (71.0/1920.0) * k4 - (17253.0/339200.0) * k5
                + (22.0/525.0) * k6 - (1.0/40.0) * *k7);
    return isfinite(*y5) && isfinite(*error) && isfinite(*k7);
}

static int integrate(int id, double y, double x, double end, int exponent,
                     int attempts, double *result)
{
    const double tolerance = pow(10.0, -(double)exponent);
    double h = fmin((end - x) / 4.0, 0.25);
    double k1 = rhs(id, x, y);
    for (int attempt = 0; attempt < attempts; ++attempt) {
        const double remaining = end - x;
        if (remaining <= 0.0) { *result = y; return 1; }
        const double step = fmin(fmin(h, 0.25), remaining);
        if (!(step > 0.0) || x + step == x) return -3;
        double y5, error, k7;
        if (!trial(id, x, y, step, k1, &y5, &error, &k7)) return -3;
        const double scale = tolerance * (1.0 + fmax(fabs(y), fabs(y5)));
        const double norm = fabs(error) / scale;
        if (!isfinite(norm)) return -3;
        if (norm <= 1.0) {
            x = step == remaining ? end : x + step;
            y = y5;
            k1 = k7;
            if (x >= end) { *result = y; return isfinite(y) ? 1 : -3; }
        }
        double factor = norm == 0.0 ? 5.0 : 0.9 * pow(norm, -0.2);
        factor = fmin(5.0, fmax(0.2, factor));
        h = step * factor;
    }
    return -3;
}

int64_t dormand_prince_54_adaptive_ode(const double *input, size_t input_length,
                                       double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 6 || input_length > MAX_INPUT_LENGTH) return -1;
    int id, y_milli, x_milli, end_milli, exponent, attempts;
    if (!integer_field(input[0], 0, 3, &id) ||
        !integer_field(input[1], -1000, 1000, &y_milli) ||
        !integer_field(input[2], -1000, 1000, &x_milli) ||
        !integer_field(input[3], -1000, 1000, &end_milli) ||
        !integer_field(input[4], 8, 9, &exponent) ||
        !integer_field(input[5], 64, 128, &attempts) || end_milli <= x_milli) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    double result;
    const int status = integrate(id, y_milli / 1000.0, x_milli / 1000.0,
                                 end_milli / 1000.0, exponent, attempts, &result);
    if (status != 1 || !isfinite(result)) return -3;
    output[0] = result;
    return 1;
}
