#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID -1e300
#define MAX_PIXELS 64
double peak_signal_to_noise_ratio(const int64_t *v, size_t n) {
    if (!v || n < 3 || n > 1 + 2 * MAX_PIXELS || v[0] < 1 || v[0] > MAX_PIXELS || n != 1 + 2 * (size_t)v[0]) return INVALID;
    size_t count = (size_t)v[0];
    double sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        int64_t a = v[i + 1], b = v[i + 1 + count];
        if (a < 0 || a > 255 || b < 0 || b > 255) return INVALID;
        if (a - b < -15 || a - b > 15) return INVALID;
        double d = (double)a - (double)b;
        sum += d * d;
    }
    double mse = sum / (double)count;
    if (mse == 0.0) return INVALID;
    return 20.0 * log10(255.0 / sqrt(mse));
}
