#include <math.h>
#include <stddef.h>
#include <stdint.h>

static double objective(double x1, double x2, double target1, double target2) {
    const double dx = x1 - target1;
    const double dy = x2 - target2;
    return -(dx * dx + dy * dy);
}

int64_t gauss_optimization(const double *values, size_t length,
                           double *output, size_t capacity) {
    if (values == NULL || length != 7) return -1;
    for (size_t i = 0; i < length; ++i) if (!isfinite(values[i])) return -1;
    if ((values[0] != 2.0 && values[0] != 3.0 && values[0] != 4.0) ||
        values[1] < 0.25 || values[1] > 4.0 ||
        values[2] < 1e-6 || values[2] > 2.0) return -1;
    for (size_t i = 3; i < 7; ++i)
        if (values[i] < -8.0 || values[i] > 8.0) return -1;
    if (output == NULL || capacity < 2) return -2;

    const double factor = values[0];
    double step = values[1];
    const double epsilon = values[2];
    double x1 = values[3], x2 = values[4];
    const double target1 = values[5], target2 = values[6];
    double error = 1.0;
    size_t iteration = 0;
    while (fabs(error) > epsilon && iteration < 256) {
        const double current = objective(x1, x2, target1, target2);
        double best = objective(x1, x2 - step, target1, target2);
        int choice = 0;
        double candidate = objective(x1, x2 + step, target1, target2);
        if (candidate > best) { best = candidate; choice = 1; }
        candidate = objective(x1 - step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 2; }
        candidate = objective(x1 + step, x2, target1, target2);
        if (candidate > best) { best = candidate; choice = 3; }
        error = best - current;
        if (choice == 0) x2 -= step;
        else if (choice == 1) x2 += step;
        else if (choice == 2) x1 -= step;
        else x1 += step;
        step /= factor;
        ++iteration;
    }
    if (fabs(error) > epsilon) return -1;
    output[0] = x1;
    output[1] = x2;
    return 2;
}
