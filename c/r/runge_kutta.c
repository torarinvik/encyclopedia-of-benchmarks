#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1e300)

static double derivative(int id, double x, double y)
{
    switch (id) {
    case 0: return y;
    case 1: return x;
    case 2: return x + y;
    case 3: return (x - y) / 2.0;
    default: return 1.0 + y * y;
    }
}

static int rk4_step(int id, double x, double y, double h, double *result)
{
    const double k1 = derivative(id, x, y);
    const double k2 = derivative(id, x + 0.5 * h, y + 0.5 * h * k1);
    const double k3 = derivative(id, x + 0.5 * h, y + 0.5 * h * k2);
    const double k4 = derivative(id, x + h, y + h * k3);
    *result = y + (1.0 / 6.0) * h * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    return isfinite(k1) && isfinite(k2) && isfinite(k3) && isfinite(k4) && isfinite(*result);
}

double runge_kutta(const int64_t *input, size_t length)
{
    if (input == NULL || length != 5) return INVALID_RESULT;
    const int64_t fid = input[0], y0m = input[1], x0m = input[2], hm = input[3], xem = input[4];
    if (fid < 0 || fid > 4 || y0m < -1000000 || y0m > 1000000 ||
        x0m < -1000000 || x0m > 1000000 || xem < -1000000 || xem > 1000000 ||
        hm < 10000 || hm > 250000 || xem <= x0m) return INVALID_RESULT;
    const double y0 = (double)y0m / 1000000.0;
    const double x0 = (double)x0m / 1000000.0;
    const double h = (double)hm / 1000000.0;
    const double x_end = (double)xem / 1000000.0;
    if (fid == 4 && (x0 < 0.0 || y0 > 0.0)) return INVALID_RESULT;
    const double ratio = (x_end - x0) / h;
    const int steps = (int)ceil(ratio);
    if (steps < 1 || steps > 64) return INVALID_RESULT;
    double x = x0, y = y0;
    for (int i = 0; i < steps; ++i) {
        double next;
        if (!rk4_step((int)fid, x, y, h, &next)) return INVALID_RESULT;
        y = next;
        x += h;
        if (!isfinite(x)) return INVALID_RESULT;
    }
    return y;
}
