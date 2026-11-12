#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 8u
#define MAX_POINTS (MAX_SIDE * MAX_SIDE)
#define MAX_INPUT (1u + 2u * MAX_POINTS)
#define MAX_OUTPUT (2u * MAX_POINTS)
#define TAU 6.283185307179586476925286766559

static void transpose(const double *source, double *destination, size_t side)
{
    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            const size_t from = 2 * (row * side + column);
            const size_t to = 2 * (column * side + row);
            destination[to] = source[from];
            destination[to + 1] = source[from + 1];
        }
    }
}

static void fft_row(double *data, size_t base, size_t side)
{
    size_t reverse = 0;
    for (size_t position = 1; position < side; ++position) {
        size_t bit = side >> 1;
        while ((reverse & bit) != 0) {
            reverse ^= bit;
            bit >>= 1;
        }
        reverse ^= bit;
        if (position < reverse) {
            const size_t left = 2 * (base + position);
            const size_t right = 2 * (base + reverse);
            double temporary = data[left]; data[left] = data[right]; data[right] = temporary;
            temporary = data[left + 1]; data[left + 1] = data[right + 1]; data[right + 1] = temporary;
        }
    }

    for (size_t block = 2; block <= side; block *= 2) {
        const size_t half = block / 2;
        const double angle_step = TAU / (double)block;
        for (size_t start = 0; start < side; start += block) {
            for (size_t offset = 0; offset < half; ++offset) {
                const double angle = angle_step * (double)offset;
                const double weight_real = cos(angle);
                const double weight_imag = -sin(angle);
                const size_t first = 2 * (base + start + offset);
                const size_t second = 2 * (base + start + offset + half);
                const double product_real = weight_real * data[second] - weight_imag * data[second + 1];
                const double product_imag = weight_real * data[second + 1] + weight_imag * data[second];
                const double first_real = data[first];
                const double first_imag = data[first + 1];
                data[first] = first_real + product_real;
                data[first + 1] = first_imag + product_imag;
                data[second] = first_real - product_real;
                data[second + 1] = first_imag - product_imag;
            }
        }
    }
}

int64_t splash2_fft_six_step(const double *input, size_t input_length,
                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 9 || input_length > MAX_INPUT) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }
    const double side_value = input[0];
    if (side_value != 2.0 && side_value != 4.0 && side_value != 8.0) return -1;
    const size_t side = (size_t)side_value;
    const size_t points = side * side;
    if (input_length != 1 + 2 * points) return -1;
    for (size_t i = 0; i < 2 * points; ++i) {
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;
    }

    double first_matrix[MAX_OUTPUT] = {0.0};
    double second_matrix[MAX_OUTPUT] = {0.0};
    for (size_t i = 0; i < 2 * points; ++i) first_matrix[i] = input[i + 1];

    /* Six-step: transpose, row FFTs, twiddle, transpose, row FFTs, transpose. */
    transpose(first_matrix, second_matrix, side);
    for (size_t row = 0; row < side; ++row) fft_row(second_matrix, row * side, side);
    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            const size_t index = 2 * (row * side + column);
            const double angle = TAU * (double)(row * column) / (double)points;
            const double cosine = cos(angle);
            const double sine = sin(angle);
            const double real = second_matrix[index];
            const double imag = second_matrix[index + 1];
            second_matrix[index] = cosine * real + sine * imag;
            second_matrix[index + 1] = cosine * imag - sine * real;
        }
    }
    transpose(second_matrix, first_matrix, side);
    for (size_t row = 0; row < side; ++row) fft_row(first_matrix, row * side, side);
    transpose(first_matrix, second_matrix, side);

    const size_t needed = 2 * points;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = second_matrix[i];
    return (int64_t)needed;
}
