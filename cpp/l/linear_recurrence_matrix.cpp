#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kModulus = 1'000'000'007;
constexpr std::size_t kMaxInputLength = 24;

void multiply_matrix(const std::int64_t *left, const std::int64_t *right,
                     std::int64_t *output, std::size_t dimension) noexcept
{
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t column = 0; column < dimension; ++column) {
            std::int64_t value = 0;
            for (std::size_t inner = 0; inner < dimension; ++inner) {
                value = (value + (left[row * dimension + inner] % kModulus) *
                                 (right[inner * dimension + column] % kModulus) % kModulus) % kModulus;
            }
            output[row * dimension + column] = value;
        }
    }
}
}

extern "C" std::int64_t linear_recurrence_matrix(const std::int64_t *input,
                                                   std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInputLength) return -1;
    const std::int64_t dimension_value = input[0];
    const std::int64_t nth_term = input[1];
    const std::int64_t constant_or_sum_included = input[2];
    if (dimension_value < 1 || dimension_value > 4 || nth_term < 0 || nth_term > 1'000'000 ||
        (constant_or_sum_included != 0 && constant_or_sum_included != 1)) return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const std::size_t matrix_count = dimension * dimension;
    if (length != 3 + matrix_count + dimension) return -1;
    if (constant_or_sum_included == 1 && nth_term < dimension_value - 1) return -1;

    std::int64_t matrix[16] = {};
    std::int64_t base_row[4] = {};
    for (std::size_t index = 0; index < matrix_count + dimension; ++index) {
        const std::int64_t value = input[3 + index];
        if (value < 0 || value >= kModulus) return -1;
        if (index < matrix_count) matrix[index] = value;
        else base_row[index - matrix_count] = value;
    }
    if (nth_term < dimension_value - constant_or_sum_included)
        return base_row[static_cast<std::size_t>(nth_term - constant_or_sum_included)];

    bool matrix_is_zero = true;
    for (std::size_t index = 0; index < matrix_count; ++index)
        if (matrix[index] != 0) matrix_is_zero = false;
    if (matrix_is_zero) return 0;

    std::int64_t result[16] = {};
    std::int64_t work[16] = {};
    for (std::size_t index = 0; index < dimension; ++index)
        result[index * dimension + index] = 1;
    std::int64_t power = nth_term - dimension_value + 1 + constant_or_sum_included;
    while (power > 0) {
        if ((power & 1) != 0) {
            multiply_matrix(result, matrix, work, dimension);
            for (std::size_t index = 0; index < matrix_count; ++index) result[index] = work[index];
        }
        power /= 2;
        multiply_matrix(matrix, matrix, work, dimension);
        for (std::size_t index = 0; index < matrix_count; ++index) matrix[index] = work[index];
    }

    std::int64_t value = 0;
    for (std::size_t index = 0; index < dimension; ++index)
        value = (value + (base_row[index] % kModulus) *
                         (result[index * dimension + dimension - 1] % kModulus) % kModulus) % kModulus;
    return value;
}
