#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64u
#define MAX_INPUT_LENGTH (1u + 2u * MAX_N + 1u)
#define MAX_SCALARS (2u * MAX_N)
#define TAU 6.283185307179586476925286766559

static void stockham_stage(const double *source, double *destination,
                           size_t n, size_t stride)
{
    for (size_t j = 0; j < n / 2; ++j) {
        const size_t column = j % stride;
        const size_t group = j / stride;
        const size_t base = group * 2 * stride + column;
        const double angle = -TAU * (double)column / (double)(2 * stride);
        const double cosine = cos(angle), sine = sin(angle);
        const size_t left = 2 * j, right = 2 * (j + n / 2);
        const double product_real = cosine * source[right] - sine * source[right + 1];
        const double product_imag = cosine * source[right + 1] + sine * source[right];
        const double first_real = source[left], first_imag = source[left + 1];
        const size_t out_left = 2 * base, out_right = 2 * (base + stride);
        destination[out_left] = first_real + product_real;
        destination[out_left + 1] = first_imag + product_imag;
        destination[out_right] = first_real - product_real;
        destination[out_right + 1] = first_imag - product_imag;
    }
}

int64_t stockham_autosort_radix2_fft(const double *input, size_t input_length,
                                     double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    const double n_value = input[0];
    if (n_value < 1.0 || n_value > (double)MAX_N || floor(n_value) != n_value) return -1;
    const size_t n = (size_t)n_value;
    if ((n & (n - 1)) != 0 || input_length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < MAX_SCALARS && i < 2 * n; ++i)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;

    double first[MAX_SCALARS] = {0.0};
    double second[MAX_SCALARS] = {0.0};
    for (size_t i = 0; i < 2 * n; ++i) first[i] = input[i + 1];
    double *source = first;
    double *destination = second;
    for (size_t stride = 1; stride < n; stride *= 2) {
        stockham_stage(source, destination, n, stride);
        double *old_source = source;
        source = destination;
        destination = old_source;
    }

    const size_t needed = 2 * n;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = source[i];
    return (int64_t)needed;
}
