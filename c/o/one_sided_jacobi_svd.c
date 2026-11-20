#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 6
#define MAX_SWEEPS 128
#define TOL 1.0e-14

int64_t one_sided_jacobi_svd(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 39) return -1;
    int64_t m64 = input[0], n64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < n64 || m64 > MAX_N || length != 2 + (size_t)(m64 * n64)) return -1;
    int m = (int)m64, n = (int)n64;
    double a[MAX_N][MAX_N] = {{0.0}};
    for (int r = 0; r < m; ++r) for (int c = 0; c < n; ++c) {
        int64_t x = input[2 + r * n + c];
        if (x < -8 || x > 8) return -1;
        a[r][c] = (double)x;
    }
    int converged = 0;
    for (int sweep = 0; sweep < MAX_SWEEPS; ++sweep) {
        int changed = 0;
        for (int p = 0; p < n; ++p) for (int q = p + 1; q < n; ++q) {
            double alpha = 0.0, beta = 0.0, gamma = 0.0;
            for (int r = 0; r < m; ++r) {
                alpha += a[r][p] * a[r][p]; beta += a[r][q] * a[r][q]; gamma += a[r][p] * a[r][q];
            }
            if (alpha == 0.0 || beta == 0.0 || fabs(gamma) <= TOL * sqrt(alpha * beta)) continue;
            double tau = (beta - alpha) / (2.0 * gamma);
            double t = tau == 0.0 ? 1.0 : (tau > 0.0 ? 1.0 : -1.0) / (fabs(tau) + sqrt(1.0 + tau * tau));
            double c = 1.0 / sqrt(1.0 + t * t), s = c * t;
            for (int r = 0; r < m; ++r) {
                double x = a[r][p], y = a[r][q];
                a[r][p] = c * x - s * y; a[r][q] = s * x + c * y;
            }
            changed = 1;
        }
        if (!changed) { converged = 1; break; }
    }
    if (!converged) return -1;
    double sigma[MAX_N] = {0.0};
    for (int c = 0; c < n; ++c) {
        for (int r = 0; r < m; ++r) sigma[c] += a[r][c] * a[r][c];
        sigma[c] = sqrt(sigma[c]);
    }
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) if (sigma[j] > sigma[i]) {
        double tmp = sigma[i]; sigma[i] = sigma[j]; sigma[j] = tmp;
    }
    double signature = 0.0;
    for (int i = 0; i < n; ++i) signature += (i + 1) * sigma[i];
    return (int64_t)(signature * 1000.0 + 0.5);
}
