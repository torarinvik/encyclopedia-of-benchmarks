#include <math.h>
#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

static int64_t quantize(double value) {
    double scaled = value * 1000000.0;
    return (int64_t)(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

static void transform(double real[64], double imag[64], size_t n) {
    size_t reverse = 0;
    for (size_t position = 1; position < n; ++position) {
        size_t bit = n >> 1;
        while ((reverse & bit) != 0) {
            reverse ^= bit;
            bit >>= 1;
        }
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (size_t block = 2; block <= n; block *= 2) {
        double angle = 6.283185307179586476925286766559 / (double)block;
        double step_real = cos(angle), step_imag = -sin(angle);
        for (size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (size_t offset = 0; offset < block / 2; ++offset) {
                size_t first = start + offset, second = first + block / 2;
                double product_real = weight_real * real[second] - weight_imag * imag[second];
                double product_imag = weight_real * imag[second] + weight_imag * real[second];
                double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real;
                imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real;
                imag[second] = first_imag - product_imag;
                double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
}

int64_t inverse_fast_fourier_transform(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > 129) return -1;
    int64_t raw_n = values[0];
    if (raw_n < 1 || raw_n > 64 || (raw_n & (raw_n - 1)) != 0 || length != 1 + 2 * (size_t)raw_n) return -1;
    size_t n = (size_t)raw_n;
    for (size_t index = 0; index < 2 * n; ++index) {
        if (values[index + 1] < -1000 || values[index + 1] > 1000) return -1;
    }
    size_t byte_count = 8 * n;
    if (output == NULL || capacity < byte_count) return -2;
    double real[64] = {0.0}, imag[64] = {0.0};
    for (size_t index = 0; index < n; ++index) { real[index] = (double)values[2 * index + 1]; imag[index] = (double)values[2 * index + 2]; }
    transform(real, imag, n);
    for (size_t index = 0; index < n; ++index) store_i64_le(output, 8 * index, quantize(real[index] / (double)n));
    return (int64_t)byte_count;
}
