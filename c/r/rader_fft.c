#include <math.h>
#include <stddef.h>
#include <stdint.h>

static void rader_fft_fft8(double *real, double *imag, int inverse)
{
    static const size_t reversed[8] = {0, 4, 2, 6, 1, 5, 3, 7};
    const double pi = 3.14159265358979323846264338327950288;
    for (size_t i = 0; i < 8; ++i) {
        size_t j = reversed[i];
        if (i < j) {
            double t = real[i]; real[i] = real[j]; real[j] = t;
            t = imag[i]; imag[i] = imag[j]; imag[j] = t;
        }
    }
    for (size_t stage = 1; stage <= 3; ++stage) {
        const size_t block = (size_t)1 << stage;
        const size_t half = block / 2;
        for (size_t start = 0; start < 8; start += block) {
            for (size_t j = 0; j < half; ++j) {
                const double sign = inverse ? 1.0 : -1.0;
                const double angle = sign * 2.0 * pi * (double)j / (double)block;
                const double wr = cos(angle), wi = sin(angle);
                const size_t even = start + j, odd = even + half;
                const double vr = real[odd] * wr - imag[odd] * wi;
                const double vi = real[odd] * wi + imag[odd] * wr;
                const double ur = real[even], ui = imag[even];
                real[even] = ur + vr; imag[even] = ui + vi;
                real[odd] = ur - vr; imag[odd] = ui - vi;
            }
        }
    }
    if (inverse)
        for (size_t i = 0; i < 8; ++i) { real[i] /= 8.0; imag[i] /= 8.0; }
}

int64_t rader_fft(const double *input, size_t input_length,
                  double *output, size_t output_capacity)
{
    static const size_t permutation[4] = {1, 2, 4, 3};
    static const size_t kernel_power[4] = {1, 3, 4, 2};
    const double pi = 3.14159265358979323846264338327950288;
    if (input == NULL || input_length != 10) return -1;
    for (size_t i = 0; i < 10; ++i)
        if (!isfinite(input[i]) || input[i] < -100.0 || input[i] > 100.0) return -1;
    if (output == NULL || output_capacity < 10) return -2;

    double ar[8] = {0}, ai[8] = {0}, br[8] = {0}, bi[8] = {0};
    for (size_t i = 0; i < 4; ++i) {
        ar[i] = input[2 * permutation[i]];
        ai[i] = input[2 * permutation[i] + 1];
        const double angle = -2.0 * pi * (double)kernel_power[i] / 5.0;
        br[i] = cos(angle); bi[i] = sin(angle);
    }
    rader_fft_fft8(ar, ai, 0);
    rader_fft_fft8(br, bi, 0);
    for (size_t i = 0; i < 8; ++i) {
        const double real = ar[i] * br[i] - ai[i] * bi[i];
        const double imag = ar[i] * bi[i] + ai[i] * br[i];
        ar[i] = real; ai[i] = imag;
    }
    rader_fft_fft8(ar, ai, 1);

    double result[10] = {0};
    for (size_t n = 0; n < 5; ++n) {
        result[0] += input[2 * n];
        result[1] += input[2 * n + 1];
    }
    for (size_t k = 1; k < 5; ++k) {
        result[2 * k] = input[0];
        result[2 * k + 1] = input[1];
    }
    for (size_t i = 0; i < 4; ++i) {
        const double real = ar[i] + (i + 4 < 8 ? ar[i + 4] : 0.0);
        const double imag = ai[i] + (i + 4 < 8 ? ai[i + 4] : 0.0);
        const size_t target = kernel_power[i];
        result[2 * target] += real; result[2 * target + 1] += imag;
    }
    for (size_t i = 0; i < 10; ++i) output[i] = result[i];
    return 10;
}
