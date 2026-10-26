/* Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { CHANNELS = 20, MAX_N = 64, MAX_SEQUENCE = 32, MAX_INPUT = 66 };
static const int amino_codes[CHANNELS] = {
    65, 82, 78, 68, 67, 81, 69, 71, 72, 73,
    76, 75, 77, 70, 80, 83, 84, 87, 89, 86
};
static const double polarity[CHANNELS] = {
    8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,
    4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9
};
static const double volume[CHANNELS] = {
    31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,
    111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0
};

static int amino_channel(int code) {
    for (int q = 0; q < CHANNELS; ++q) if (amino_codes[q] == code) return q;
    return -1;
}

static void fft(double *re, double *im, size_t offset, size_t n, int inverse) {
    size_t j = 0;
    for (size_t i = 1; i < n; ++i) {
        size_t bit = n >> 1;
        while (j & bit) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            double t = re[offset + i]; re[offset + i] = re[offset + j]; re[offset + j] = t;
            t = im[offset + i]; im[offset + i] = im[offset + j]; im[offset + j] = t;
        }
    }
    for (size_t span = 2; span <= n; span *= 2) {
        const double angle = (inverse ? 1.0 : -1.0) * 6.2831853071795864769 / (double)span;
        const double cr = cos(angle), ci = sin(angle);
        for (size_t start = 0; start < n; start += span) {
            double wr = 1.0, wi = 0.0;
            for (size_t k = 0; k < span / 2; ++k) {
                const size_t u = offset + start + k, v = u + span / 2;
                const double pr = wr * re[v] - wi * im[v];
                const double pi = wr * im[v] + wi * re[v];
                const double ur = re[u], ui = im[u];
                re[u] = ur + pr; im[u] = ui + pi;
                re[v] = ur - pr; im[v] = ui - pi;
                const double next_wr = wr * cr - wi * ci;
                wi = wr * ci + wi * cr; wr = next_wr;
            }
        }
    }
    if (!inverse)
        for (size_t i = 0; i < n; ++i) { re[offset + i] /= (double)n; im[offset + i] /= (double)n; }
}

int64_t mafft_falign_fft_lag_correlation(const double *input, size_t length,
                                         double *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    for (size_t q = 0; q < length; ++q)
        if (!isfinite(input[q]) || trunc(input[q]) != input[q]) return -1;
    if (input[0] < 1 || input[0] > MAX_SEQUENCE || input[1] < 1 || input[1] > MAX_SEQUENCE) return -1;
    const size_t n1 = (size_t)input[0], n2 = (size_t)input[1];
    if (length != 2 + n1 + n2) return -1;
    for (size_t q = 2; q < length; ++q)
        if (input[q] < 65.0 || input[q] > 90.0 || amino_channel((int)input[q]) < 0) return -1;
    size_t n = 1; while (n <= (n1 > n2 ? n1 : n2)) n *= 2;
    if (output == NULL || capacity < n) return -2;

    double r1[MAX_N] = {0}, i1[MAX_N] = {0};
    double r2[MAX_N] = {0}, i2[MAX_N] = {0};
    double re[MAX_N] = {0}, im[MAX_N] = {0};
    double mean_p = 0.0, mean_v = 0.0;
    for (size_t ch = 0; ch < CHANNELS; ++ch) { mean_p += polarity[ch]; mean_v += volume[ch]; }
    mean_p /= CHANNELS; mean_v /= CHANNELS;
    double var_p = 0.0, var_v = 0.0;
    for (size_t ch = 0; ch < CHANNELS; ++ch) {
        const double dp = polarity[ch] - mean_p, dv = volume[ch] - mean_v;
        var_p += dp * dp; var_v += dv * dv;
    }
    const double sd_p = sqrt(var_p / CHANNELS), sd_v = sqrt(var_v / CHANNELS);
    for (size_t p = 0; p < n1; ++p) {
        const size_t ch = (size_t)amino_channel((int)input[2 + p]);
        r1[p] = (polarity[ch] - mean_p) / sd_p; i1[p] = (volume[ch] - mean_v) / sd_v;
    }
    for (size_t p = 0; p < n2; ++p) {
        const size_t ch = (size_t)amino_channel((int)input[2 + n1 + p]);
        r2[p] = (polarity[ch] - mean_p) / sd_p; i2[p] = (volume[ch] - mean_v) / sd_v;
    }
    fft(r1, i1, 0, n, 0); fft(r2, i2, 0, n, 0);
    for (size_t k = 0; k < n; ++k) {
        re[k] = r1[k] * r2[k] + i1[k] * i2[k];
        im[k] = -r1[k] * i2[k] + i1[k] * r2[k];
    }
    fft(re, im, 0, n, 1);
    for (size_t q = 0; q < n; ++q) output[q] = re[(n / 2 + n - q) % n];
    return (int64_t)n;
}
