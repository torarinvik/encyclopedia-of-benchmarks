/* Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float
   (intersrv.com/~dcross/fft.html).
   Modified for a bounded float64-slice ABI; the binary32 FFT kernel is retained. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

static void transform(float real[16], float imag[16], size_t n, int inverse) {
    size_t bits = 0;
    for (size_t value = n; value > 1; value >>= 1) ++bits;
    for (size_t i = 0; i < n; ++i) {
        size_t source = i, reverse = 0;
        for (size_t b = 0; b < bits; ++b) { reverse = (reverse << 1) | (source & 1u); source >>= 1; }
        if (i < reverse) {
            float t = real[i]; real[i] = real[reverse]; real[reverse] = t;
            t = imag[i]; imag[i] = imag[reverse]; imag[reverse] = t;
        }
    }
    double angle_numerator = inverse ? -2.0 * 3.14159265358979323846 : 2.0 * 3.14159265358979323846;
    size_t block_end = 1;
    for (size_t block_size = 2; block_size <= n; block_size <<= 1) {
        double delta = angle_numerator / (double)block_size;
        double sm2 = sin(-2.0 * delta), sm1 = sin(-delta);
        double cm2 = cos(-2.0 * delta), cm1 = cos(-delta), w = 2.0 * cm1;
        for (size_t start = 0; start < n; start += block_size) {
            double ar2 = cm2, ar1 = cm1, ai2 = sm2, ai1 = sm1;
            for (size_t offset = 0; offset < block_end; ++offset) {
                double ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0;
                double ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0;
                size_t first = start + offset, second = first + block_end;
                double tr = ar0 * real[second] - ai0 * imag[second];
                double ti = ar0 * imag[second] + ai0 * real[second];
                real[second] = (float)(real[first] - tr); imag[second] = (float)(imag[first] - ti);
                real[first] = (float)(real[first] + tr); imag[first] = (float)(imag[first] + ti);
            }
        }
        block_end = block_size;
    }
    if (inverse) for (size_t i = 0; i < n; ++i) {
        real[i] = (float)((double)real[i] / (double)n);
        imag[i] = (float)((double)imag[i] / (double)n);
    }
}

int64_t mibench_telecomm_fft(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length < 6 || length > 34) return -1;
    double nd = input[0], inverse_d = input[1];
    if (!isfinite(nd) || nd != trunc(nd) || nd < 2.0 || nd > 16.0
        || !isfinite(inverse_d) || inverse_d != trunc(inverse_d)
        || (inverse_d != 0.0 && inverse_d != 1.0)) return -1;
    size_t n = (size_t)nd;
    if ((n & (n - 1)) != 0 || length != 2 + 2 * n) return -1;
    for (size_t i = 2; i < length; ++i)
        if (!isfinite(input[i]) || fabs(input[i]) > 8.0) return -1;
    size_t required = 2 * n;
    if (output == NULL || capacity < required) return -2;
    float real[16] = {0}, imag[16] = {0};
    for (size_t i = 0; i < n; ++i) { real[i] = (float)input[2 + i]; imag[i] = (float)input[2 + n + i]; }
    transform(real, imag, n, inverse_d != 0.0);
    double staged[32];
    for (size_t i = 0; i < n; ++i) { staged[2 * i] = (double)real[i]; staged[2 * i + 1] = (double)imag[i]; }
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
