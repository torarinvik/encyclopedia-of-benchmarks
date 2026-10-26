#include <math.h>
#include <stddef.h>

long long tsvc_s1251_per_element_dual_update(const double *x, size_t l,
                                             double *y, size_t c) {
    if (!x || l < 6 || l > 321) return -1;
    double r = x[0];
    if (!isfinite(r) || trunc(r) != r || r < 1 || r > 64) return -1;
    size_t n = (size_t)r;
    if (l != 1 + 5 * n) return -1;
    for (size_t i = 1; i < l; ++i)
        if (!isfinite(x[i]) || trunc(x[i]) != x[i] || fabs(x[i]) > 1) return -1;
    if (!y || c < 2 * n) return -2;
    double a[64], b[64];
    for (size_t i = 0; i < n; ++i) {
        double saved = x[1 + n + i] + x[1 + 2 * n + i];
        b[i] = x[1 + i] + x[1 + 3 * n + i];
        a[i] = saved * x[1 + 4 * n + i];
    }
    for (size_t i = 0; i < n; ++i) { y[i] = a[i]; y[n + i] = b[i]; }
    return (long long)(2 * n);
}
