#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int max_dimension = 6;
constexpr std::size_t max_input_length = 1 + max_dimension * max_dimension;
constexpr std::int64_t invalid_result = std::numeric_limits<std::int64_t>::min();

std::int64_t determinant_recursive(const std::int64_t *matrix, int dimension) noexcept {
    if (dimension == 1) return matrix[0];

    std::int64_t result = 0;
    std::int64_t minor[(max_dimension - 1) * (max_dimension - 1)];
    for (int column = 0; column < dimension; ++column) {
        int minor_index = 0;
        for (int row = 1; row < dimension; ++row) {
            for (int source_column = 0; source_column < dimension; ++source_column) {
                if (source_column != column) minor[minor_index++] = matrix[row * dimension + source_column];
            }
        }
        const auto term = matrix[column] * determinant_recursive(minor, dimension - 1);
        result += column % 2 == 0 ? term : -term;
    }
    return result;
}
}

extern "C" std::int64_t determinant(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return invalid_result;
    const auto dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > max_dimension) return invalid_result;
    const int dimension = static_cast<int>(dimension_value);
    if (length != static_cast<std::size_t>(1 + dimension * dimension)) return invalid_result;
    for (int index = 0; index < dimension * dimension; ++index) {
        if (input[1 + index] < -9 || input[1 + index] > 9) return invalid_result;
    }
    return determinant_recursive(input + 1, dimension);
}
