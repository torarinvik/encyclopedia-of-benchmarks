#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64u
#define MAX_INPUT_LENGTH (1u + 2u * MAX_N + 1u)
#define TAU 6.283185307179586476925286766559

int64_t direct_discrete_fourier_transform(const double *input, size_t input_length,
                                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i)
        if (!isfinite(input[i])) return -1;
    const double n_value = input[0];
    if (n_value < 1.0 || n_value > (double)MAX_N || floor(n_value) != n_value) return -1;
    const size_t n = (size_t)n_value;
    if (input_length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;

    const size_t needed = 2 * n;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t k = 0; k < n; ++k) {
        double real_sum = 0.0;
        double imag_sum = 0.0;
        for (size_t j = 0; j < n; ++j) {
            const double angle = -TAU * (double)j * (double)k / (double)n;
            const double cosine = cos(angle);
            const double sine = sin(angle);
            const double sample_real = input[1 + 2 * j];
            const double sample_imag = input[2 + 2 * j];
            real_sum += sample_real * cosine + sample_imag * sine;
            imag_sum += sample_imag * cosine - sample_real * sine;
        }
        output[2 * k] = real_sum;
        output[2 * k + 1] = imag_sum;
    }
    return (int64_t)needed;
}

