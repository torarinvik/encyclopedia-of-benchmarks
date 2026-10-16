#include <complex.h>
#include <stddef.h>
#include <stdint.h>
#include <math.h>

double durand_kerner_roots(const int64_t *v, size_t n) {
    if (!v || n != 3 || v[0] == 0 || v[0] < -4 || v[0] > 4 ||
        v[1] < 0 || v[1] > 2 || v[2] < 0 || v[2] > 1) return -1.0e300;
    const double d = (double)v[0], s = d > 0 ? 1.0 : -1.0;
    const double q = sqrt(3.0) / 2.0;
    double complex z[3] = {s, s * (-0.5 + q * I), s * (-0.5 - q * I)};
    for (int it = 0; it < 100; ++it) {
        double complex next[3];
        double change = 0.0;
        for (int i = 0; i < 3; ++i) {
            double complex den = 1.0;
            for (int j = 0; j < 3; ++j) if (i != j) den *= z[i] - z[j];
            next[i] = z[i] - (z[i] * z[i] * z[i] - d) / den;
            double delta = cabs(next[i] - z[i]);
            if (delta > change) change = delta;
        }
        for (int i = 0; i < 3; ++i) z[i] = next[i];
        if (change < 1.0e-14) break;
    }
    int i = (int)v[1];
    return v[2] == 0 ? creal(z[i]) : cimag(z[i]);
}
