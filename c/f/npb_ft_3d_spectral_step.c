#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 4
#define MAX_POINTS (MAX_SIDE * MAX_SIDE * MAX_SIDE)
#define MAX_STEPS 6
#define MAX_INPUT_LENGTH (2 + 2 * MAX_POINTS)
#define CHECKSUM_TERMS 64
#define TAU 6.28318530717958647692528676655900577
#define ALPHA 1.0e-6

static int bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

static void fft_line(double *real, double *imag, size_t n, int inverse) {
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

static void axis_transform(double *real, double *imag, size_t n, size_t axis, int inverse) {
    double line_real[MAX_SIDE], line_imag[MAX_SIDE];
    for (size_t a = 0; a < n; ++a) for (size_t b = 0; b < n; ++b) {
        for (size_t p = 0; p < n; ++p) {
            size_t x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            const size_t index = (x * n + y) * n + z;
            line_real[p] = real[index]; line_imag[p] = imag[index];
        }
        fft_line(line_real, line_imag, n, inverse);
        for (size_t p = 0; p < n; ++p) {
            size_t x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            const size_t index = (x * n + y) * n + z;
            real[index] = line_real[p]; imag[index] = line_imag[p];
        }
    }
}

static void transform3d(double *real, double *imag, size_t n, int inverse) {
    axis_transform(real, imag, n, 2, inverse);
    axis_transform(real, imag, n, 1, inverse);
    axis_transform(real, imag, n, 0, inverse);
}

static int signed_frequency(size_t index, size_t n) {
    return index <= n / 2 ? (int)index : (int)index - (int)n;
}

int64_t npb_ft_3d_spectral_step(const double *input, size_t length,
                               double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (!bounded_integer(input[0], 2.0, (double)MAX_SIDE)
            || !bounded_integer(input[1], 1.0, (double)MAX_STEPS)) return -1;
    const size_t n = (size_t)input[0], steps = (size_t)input[1];
    if ((n != 2 && n != 4) || length != 2 + 2 * n * n * n) return -1;
    const size_t volume = n * n * n, needed = 2 * steps;
    for (size_t i = 2; i < length; ++i)
        if (!isfinite(input[i]) || input[i] < -1.0 || input[i] > 1.0) return -1;
    if (output == NULL || capacity < needed) return -2;

    double spectrum_real[MAX_POINTS] = {0}, spectrum_imag[MAX_POINTS] = {0};
    double work_real[MAX_POINTS] = {0}, work_imag[MAX_POINTS] = {0};
    for (size_t i = 0; i < volume; ++i) {
        spectrum_real[i] = input[2 + 2 * i];
        spectrum_imag[i] = input[2 + 2 * i + 1];
    }
    transform3d(spectrum_real, spectrum_imag, n, 0);

    for (size_t step = 1; step <= steps; ++step) {
        for (size_t x = 0; x < n; ++x) for (size_t y = 0; y < n; ++y) for (size_t z = 0; z < n; ++z) {
            const size_t index = (x * n + y) * n + z;
            const int kx = signed_frequency(x, n), ky = signed_frequency(y, n), kz = signed_frequency(z, n);
            const double radius_squared = (double)(kx * kx + ky * ky + kz * kz);
            const double factor = exp(-4.0 * 3.14159265358979323846264338327950288
                                      * 3.14159265358979323846264338327950288
                                      * ALPHA * (double)step * radius_squared);
            work_real[index] = spectrum_real[index] * factor;
            work_imag[index] = spectrum_imag[index] * factor;
        }
        transform3d(work_real, work_imag, n, 1);
        double sum_real = 0.0, sum_imag = 0.0;
        for (size_t j = 1; j <= CHECKSUM_TERMS; ++j) {
            const size_t x = (j - 1) % n, y = (3 * j - 1) % n, z = (5 * j - 1) % n;
            const size_t index = (x * n + y) * n + z;
            sum_real += work_real[index]; sum_imag += work_imag[index];
        }
        output[2 * (step - 1)] = sum_real / (double)volume;
        output[2 * (step - 1) + 1] = sum_imag / (double)volume;
    }
    return (int64_t)needed;
}
