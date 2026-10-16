#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SIGNAL_LENGTH 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_SIGNAL_LENGTH + 1)
#define MAX_FFT_LENGTH (2 * MAX_SIGNAL_LENGTH)
#define MIN_SAMPLE (-64)
#define MAX_SAMPLE 64
#define SAMPLE_SCALE 16.0
#define PI 3.14159265358979323846264338327950288

typedef struct { double real, imag; } Complex;

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void fft(Complex *values, size_t n, int inverse) {
    size_t reverse = 0;
    for (size_t position = 1; position < n; ++position) {
        size_t bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) { Complex temporary = values[position]; values[position] = values[reverse]; values[reverse] = temporary; }
    }
    for (size_t block = 2; block <= n; block *= 2) {
        const double direction = inverse ? -1.0 : 1.0;
        const double angle = -2.0 * PI / (double)block * direction;
        const double step_real = cos(angle), step_imag = sin(angle);
        for (size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (size_t offset = 0; offset < block / 2; ++offset) {
                const size_t first = start + offset, second = first + block / 2;
                const double product_real = weight_real * values[second].real - weight_imag * values[second].imag;
                const double product_imag = weight_real * values[second].imag + weight_imag * values[second].real;
                const double first_real = values[first].real, first_imag = values[first].imag;
                values[first].real = first_real + product_real; values[first].imag = first_imag + product_imag;
                values[second].real = first_real - product_real; values[second].imag = first_imag - product_imag;
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
        }
    }
    if (inverse) for (size_t index = 0; index < n; ++index) { values[index].real /= (double)n; values[index].imag /= (double)n; }
}

int64_t convolution_fft(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_a_count = input[0], raw_b_count = input[1];
    if (raw_a_count < 1 || raw_a_count > MAX_SIGNAL_LENGTH || raw_b_count < 1 || raw_b_count > MAX_SIGNAL_LENGTH) return -1;
    const size_t a_count = (size_t)raw_a_count, b_count = (size_t)raw_b_count;
    if (length != 2 + a_count + b_count) return -1;
    for (size_t index = 0; index < a_count + b_count; ++index) if (input[index + 2] < MIN_SAMPLE || input[index + 2] > MAX_SAMPLE) return -1;

    const size_t result_count = a_count + b_count - 1;
    const size_t byte_count = result_count * 16;
    if (output == NULL || capacity < byte_count) return -2;
    size_t fft_length = 1;
    while (fft_length < result_count) fft_length *= 2;
    Complex a[MAX_FFT_LENGTH] = {{0.0, 0.0}}, b[MAX_FFT_LENGTH] = {{0.0, 0.0}}, product[MAX_FFT_LENGTH] = {{0.0, 0.0}};
    for (size_t index = 0; index < a_count; ++index) a[index].real = (double)input[index + 2] / SAMPLE_SCALE;
    for (size_t index = 0; index < b_count; ++index) b[index].real = (double)input[a_count + index + 2] / SAMPLE_SCALE;
    fft(a, fft_length, 0); fft(b, fft_length, 0);
    for (size_t index = 0; index < fft_length; ++index) {
        product[index].real = a[index].real * b[index].real - a[index].imag * b[index].imag;
        product[index].imag = a[index].real * b[index].imag + a[index].imag * b[index].real;
    }
    fft(product, fft_length, 1);
    for (size_t index = 0; index < result_count; ++index) {
        write_f64_le(output, index * 16, product[index].real);
        write_f64_le(output, index * 16 + 8, product[index].imag);
    }
    return (int64_t)byte_count;
}
