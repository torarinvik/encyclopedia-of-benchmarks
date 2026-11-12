#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_STEPS 8
#define MAX_INPUT_LENGTH (2u + 4u * MAX_N)
#define TAU 6.28318530717958647692528676655900577

static int bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

static void fft(double *real, double *imag, size_t n, int inverse) {
    size_t reverse = 0;
    for (size_t position = 1; position < n; ++position) {
        size_t bit = n >> 1;
        for (; bit != 0 && (reverse & bit) != 0; bit >>= 1) reverse ^= bit;
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (size_t block = 2; block <= n; block <<= 1) {
        const double angle = (inverse ? 1.0 : -1.0) * TAU / (double)block;
        const double step_real = cos(angle), step_imag = sin(angle);
        for (size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (size_t offset = 0; offset < block / 2; ++offset) {
                const size_t first = start + offset, second = first + block / 2;
                const double product_real = weight_real * real[second] - weight_imag * imag[second];
                const double product_imag = weight_real * imag[second] + weight_imag * real[second];
                const double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) for (size_t i = 0; i < n; ++i) { real[i] /= (double)n; imag[i] /= (double)n; }
}

static double normalize(double *real, double *imag, size_t n) {
    double norm_squared = 0.0;
    for (size_t i = 0; i < n; ++i) norm_squared += real[i] * real[i] + imag[i] * imag[i];
    const double norm = sqrt(norm_squared);
    for (size_t i = 0; i < n; ++i) { real[i] /= norm; imag[i] /= norm; }
    return norm;
}

int64_t split_operator_imaginary_time(const double *input, size_t length,
                                      double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (!bounded_integer(input[0], 2.0, MAX_N) || !bounded_integer(input[1], 0.0, MAX_STEPS)) return -1;
    const size_t n = (size_t)input[0], steps = (size_t)input[1];
    if ((n & (n - 1)) != 0 || length != 2 + 4 * n) return -1;
    for (size_t i = 2; i < length; ++i) if (!isfinite(input[i])) return -1;
    const size_t momentum_start = 2 + n, state_start = 2 + 2 * n, output_count = 2 * n;
    for (size_t i = 0; i < n; ++i)
        if (input[2 + i] < 0.25 || input[2 + i] > 1.0
                || input[momentum_start + i] < 0.25 || input[momentum_start + i] > 1.0
                || fabs(input[state_start + 2 * i]) > 1.0
                || fabs(input[state_start + 2 * i + 1]) > 1.0) return -1;

    double real[MAX_N], imag[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        real[i] = input[state_start + 2 * i];
        imag[i] = input[state_start + 2 * i + 1];
    }
    double norm_squared = 0.0;
    for (size_t i = 0; i < n; ++i) norm_squared += real[i] * real[i] + imag[i] * imag[i];
    if (!(norm_squared > 0.0)) return -1;
    if (output == NULL || capacity < output_count) return -2;
    normalize(real, imag, n);

    for (size_t step = 0; step < steps; ++step) {
        for (size_t i = 0; i < n; ++i) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        fft(real, imag, n, 0);
        for (size_t i = 0; i < n; ++i) {
            real[i] *= input[momentum_start + i]; imag[i] *= input[momentum_start + i];
        }
        fft(real, imag, n, 1);
        for (size_t i = 0; i < n; ++i) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        normalize(real, imag, n);
    }
    for (size_t i = 0; i < n; ++i) { output[2 * i] = real[i]; output[2 * i + 1] = imag[i]; }
    return (int64_t)output_count;
}
