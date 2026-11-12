#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 8;
constexpr std::size_t max_points = max_side * max_side;
constexpr std::size_t max_input = 1 + 2 * max_points;
constexpr std::size_t max_output = 2 * max_points;
constexpr double tau = 6.283185307179586476925286766559;

void transpose(const double *source, double *destination, std::size_t side) noexcept
{
    for (std::size_t row = 0; row < side; ++row) {
        for (std::size_t column = 0; column < side; ++column) {
            const std::size_t from = 2 * (row * side + column);
            const std::size_t to = 2 * (column * side + row);
            destination[to] = source[from];
            destination[to + 1] = source[from + 1];
        }
    }
}

void fft_row(double *data, std::size_t base, std::size_t side) noexcept
{
    std::size_t reverse = 0;
    for (std::size_t position = 1; position < side; ++position) {
        std::size_t bit = side >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            const std::size_t left = 2 * (base + position), right = 2 * (base + reverse);
            double temporary = data[left]; data[left] = data[right]; data[right] = temporary;
            temporary = data[left + 1]; data[left + 1] = data[right + 1]; data[right + 1] = temporary;
        }
    }
    for (std::size_t block = 2; block <= side; block *= 2) {
        const std::size_t half = block / 2;
        const double angle_step = tau / static_cast<double>(block);
        for (std::size_t start = 0; start < side; start += block) {
            for (std::size_t offset = 0; offset < half; ++offset) {
                const double angle = angle_step * static_cast<double>(offset);
                const double weight_real = std::cos(angle), weight_imag = -std::sin(angle);
                const std::size_t first = 2 * (base + start + offset);
                const std::size_t second = 2 * (base + start + offset + half);
                const double product_real = weight_real * data[second] - weight_imag * data[second + 1];
                const double product_imag = weight_real * data[second + 1] + weight_imag * data[second];
                const double first_real = data[first], first_imag = data[first + 1];
                data[first] = first_real + product_real;
                data[first + 1] = first_imag + product_imag;
                data[second] = first_real - product_real;
                data[second + 1] = first_imag - product_imag;
            }
        }
    }
}
}

extern "C" std::int64_t splash2_fft_six_step(const double *input, std::size_t input_length,
                                             double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 9 || input_length > max_input) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    const double side_value = input[0];
    if (side_value != 2.0 && side_value != 4.0 && side_value != 8.0) return -1;
    const auto side = static_cast<std::size_t>(side_value);
    const std::size_t points = side * side;
    if (input_length != 1 + 2 * points) return -1;
    for (std::size_t i = 0; i < 2 * points; ++i) {
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;
    }

    double first_matrix[max_output]{};
    double second_matrix[max_output]{};
    for (std::size_t i = 0; i < 2 * points; ++i) first_matrix[i] = input[i + 1];
    transpose(first_matrix, second_matrix, side);
    for (std::size_t row = 0; row < side; ++row) fft_row(second_matrix, row * side, side);
    for (std::size_t row = 0; row < side; ++row) {
        for (std::size_t column = 0; column < side; ++column) {
            const std::size_t index = 2 * (row * side + column);
            const double angle = tau * static_cast<double>(row * column) / static_cast<double>(points);
            const double cosine = std::cos(angle), sine = std::sin(angle);
            const double real = second_matrix[index], imag = second_matrix[index + 1];
            second_matrix[index] = cosine * real + sine * imag;
            second_matrix[index + 1] = cosine * imag - sine * real;
        }
    }
    transpose(second_matrix, first_matrix, side);
    for (std::size_t row = 0; row < side; ++row) fft_row(first_matrix, row * side, side);
    transpose(first_matrix, second_matrix, side);

    const std::size_t needed = 2 * points;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = second_matrix[i];
    return static_cast<std::int64_t>(needed);
}
