#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, SCALE = 256, MAX_INPUT = 98 };
#define INVALID_RESULT (-1.0e300)
#define TAU 6.283185307179586476925286766559005768

static void fft(double real[MAX_N], double imag[MAX_N], size_t n, int inverse) {
    size_t j = 0;
    for (size_t i = 1; i < n; ++i) {
        size_t bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            double temporary = real[i]; real[i] = real[j]; real[j] = temporary;
            temporary = imag[i]; imag[i] = imag[j]; imag[j] = temporary;
        }
    }
    for (size_t width = 2; width <= n; width <<= 1) {
        const double angle = (inverse ? 1.0 : -1.0) * TAU / (double)width;
        const double step_real = cos(angle), step_imag = sin(angle);
        const size_t half = width >> 1;
        for (size_t start = 0; start < n; start += width) {
            double twiddle_real = 1.0, twiddle_imag = 0.0;
            for (size_t offset = 0; offset < half; ++offset) {
                const size_t even = start + offset, odd = even + half;
                const double odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                const double odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                real[odd] = real[even] - odd_real;
                imag[odd] = imag[even] - odd_imag;
                real[even] += odd_real;
                imag[even] += odd_imag;
                const double next_real = twiddle_real * step_real - twiddle_imag * step_imag;
                twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) for (size_t i = 0; i < n; ++i) { real[i] /= (double)n; imag[i] /= (double)n; }
}

double quantum_spectral_energy_expectation(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT) return INVALID_RESULT;
    const int64_t n_value = values[0];
    if (n_value < 2 || n_value > MAX_N || (n_value & (n_value - 1)) != 0) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    if (length != 1 + 3 * n) return INVALID_RESULT;

    int64_t norm = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t potential = values[1 + i];
        const int64_t real_q = values[1 + n + i];
        const int64_t imag_q = values[1 + 2 * n + i];
        if (potential < -2048 || potential > 2048 ||
            real_q < -2048 || real_q > 2048 || imag_q < -2048 || imag_q > 2048)
            return INVALID_RESULT;
        norm += real_q * real_q + imag_q * imag_q;
    }
    if (norm != (int64_t)SCALE * SCALE * (int64_t)n) return INVALID_RESULT;

    double real[MAX_N] = {0.0}, imag[MAX_N] = {0.0};
    for (size_t i = 0; i < n; ++i) {
        real[i] = (double)values[1 + n + i] / SCALE;
        imag[i] = (double)values[1 + 2 * n + i] / SCALE;
    }
    fft(real, imag, n, 0);
    for (size_t i = 0; i < n; ++i) {
        const int64_t frequency = i <= n / 2 ? (int64_t)i : (int64_t)i - (int64_t)n;
        const double wave_number = TAU * (double)frequency;
        const double multiplier = 0.5 * wave_number * wave_number;
        real[i] *= multiplier;
        imag[i] *= multiplier;
    }
    fft(real, imag, n, 1);

    double total = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const double psi_real = (double)values[1 + n + i] / SCALE;
        const double psi_imag = (double)values[1 + 2 * n + i] / SCALE;
        const double potential = (double)values[1 + i] / SCALE;
        total += psi_real * (real[i] + potential * psi_real)
               + psi_imag * (imag[i] + potential * psi_imag);
    }
    return total / (double)n;
}
