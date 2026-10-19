#include <cstddef>
#include <cstdint>

namespace {
constexpr size_t matrix_elements = 16;
constexpr int64_t max_iterations = 10000;
}

extern "C" int64_t matmul_f64_4x4(const double *input, size_t input_length,
                                  double *output, size_t output_capacity)
{
    if (input == nullptr || input_length != 1) return -1;
    const double requested = input[0];
    if (!(requested >= 1.0 && requested <= static_cast<double>(max_iterations)) ||
        requested != static_cast<double>(static_cast<int64_t>(requested))) return -1;
    const int64_t iterations = static_cast<int64_t>(requested);

    constexpr double a[4][4] = {
        {4.5, 1.3, 6.0, 4.1}, {2.5, 7.2, 7.7, 1.7},
        {6.7, 1.3, 9.4, 1.3}, {1.1, 2.2, 3.0, 2.1},
    };
    constexpr double b[4][4] = {
        {1.0, 7.9, 5.1, 3.4}, {6.6, 2.8, 5.4, 9.2},
        {5.0, 4.1, 4.1, 9.9}, {8.4, 3.7, 9.5, 6.4},
    };
    double result[matrix_elements];
    for (int64_t iteration = 0; iteration < iterations; ++iteration) {
        for (size_t row = 0; row < 4; ++row) {
            for (size_t column = 0; column < 4; ++column) {
                double sum = a[row][0] * b[0][column];
                sum += a[row][1] * b[1][column];
                sum += a[row][2] * b[2][column];
                sum += a[row][3] * b[3][column];
                result[row * 4 + column] = sum;
            }
        }
    }
    if (output == nullptr || output_capacity < matrix_elements) return -2;
    for (size_t index = 0; index < matrix_elements; ++index) output[index] = result[index];
    return static_cast<int64_t>(matrix_elements);
}
