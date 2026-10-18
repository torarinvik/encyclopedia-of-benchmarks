#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_SAMPLES 3u
#define MAX_SAMPLES 8u
#define MAX_INPUT 19u
#define MAX_OUTPUT 12u

int64_t pca(const double *input, size_t input_length, double *output, size_t capacity) {
    if (input == NULL || input_length < 9u || input_length > MAX_INPUT) return -1;
    if (input[1] != 2.0 || input[2] != 1.0) return -1;
    if (input[0] != 3.0 && input[0] != 4.0 && input[0] != 5.0 && input[0] != 6.0 && input[0] != 7.0 && input[0] != 8.0) return -1;
    const size_t n = (size_t)input[0];
    if (input_length != 3u + 2u * n) return -1;
    double x[MAX_SAMPLES], y[MAX_SAMPLES], z0[MAX_SAMPLES], z1[MAX_SAMPLES];
    double mean0 = 0.0, mean1 = 0.0;
    for (size_t i = 0; i < n; ++i) {
        x[i] = input[3u + 2u * i]; y[i] = input[4u + 2u * i];
        if (x[i] != x[i] || y[i] != y[i] || fabs(x[i]) > 1000.0 || fabs(y[i]) > 1000.0) return -1;
        mean0 += x[i]; mean1 += y[i];
    }
    mean0 /= (double)n; mean1 /= (double)n;
    double sum0 = 0.0, sum1 = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const double d0 = x[i] - mean0, d1 = y[i] - mean1;
        sum0 += d0 * d0; sum1 += d1 * d1;
    }
    const double denom = (double)(n - 1u);
    if (sum0 <= 0.0 || sum1 <= 0.0) return -1;
    const double scale0 = sqrt(sum0 / denom), scale1 = sqrt(sum1 / denom);
    double a = 0.0, b = 0.0, d = 0.0;
    for (size_t i = 0; i < n; ++i) {
        z0[i] = (x[i] - mean0) / scale0; z1[i] = (y[i] - mean1) / scale1;
        a += z0[i] * z0[i]; b += z0[i] * z1[i]; d += z1[i] * z1[i];
    }
    a /= denom; b /= denom; d /= denom;
    const double root = sqrt((a - d) * (a - d) + 4.0 * b * b);
    const double lambda0 = 0.5 * (a + d + root), lambda1 = 0.5 * (a + d - root);
    if (lambda0 - lambda1 <= 1e-8) return -1;
    double vx, vy;
    if (b == 0.0) { vx = a >= d ? 1.0 : 0.0; vy = a >= d ? 0.0 : 1.0; }
    else { vx = b; vy = lambda0 - a; const double norm = sqrt(vx * vx + vy * vy); if (norm == 0.0) return -1; vx /= norm; vy /= norm; }
    if ((fabs(vx) >= fabs(vy) && vx < 0.0) || (fabs(vy) > fabs(vx) && vy < 0.0)) { vx = -vx; vy = -vy; }
    double staged[MAX_OUTPUT];
    for (size_t i = 0; i < n; ++i) staged[i] = z0[i] * vx + z1[i] * vy;
    staged[n] = vx; staged[n + 1u] = vy; staged[n + 2u] = lambda0; staged[n + 3u] = lambda1;
    const size_t output_size = n + 4u;
    if (output == NULL || capacity < output_size) return -2;
    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
