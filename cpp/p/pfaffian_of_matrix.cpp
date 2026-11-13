#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_dimension = 16;
constexpr std::size_t max_parseable = 258;
constexpr std::int64_t modulus = 998244353;

std::int64_t normalize(std::int64_t value) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::int64_t multiply(std::int64_t left, std::int64_t right) {
    return (left * right) % modulus;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}
}  // namespace

extern "C" std::int64_t pfaffian_of_matrix(const std::int64_t* input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 5 || length > max_parseable) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto dimension = static_cast<std::size_t>(2 * input[0]);
    if (length != 1 + dimension * dimension) return -1;

    std::array<std::int64_t, max_dimension * max_dimension> matrix{};
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t column = 0; column < dimension; ++column) {
            const auto value = input[1 + row * dimension + column];
            if (value < 0 || value >= modulus) return -1;
            matrix[row * max_dimension + column] = value;
        }
    }
    for (std::size_t row = 0; row < dimension; ++row) {
        if (matrix[row * max_dimension + row] != 0) return -1;
        for (std::size_t column = row + 1; column < dimension; ++column) {
            if ((matrix[row * max_dimension + column]
                    + matrix[column * max_dimension + row]) % modulus != 0) return -1;
        }
    }

    std::int64_t result = 1;
    for (std::size_t pivot_index = 0; pivot_index < dimension; pivot_index += 2) {
        std::size_t partner = pivot_index + 1;
        while (partner < dimension
                && matrix[pivot_index * max_dimension + partner] == 0) ++partner;
        if (partner == dimension) return 0;
        if (partner != pivot_index + 1) {
            const auto swapped = pivot_index + 1;
            for (std::size_t k = 0; k < dimension; ++k)
                std::swap(matrix[swapped * max_dimension + k], matrix[partner * max_dimension + k]);
            for (std::size_t k = 0; k < dimension; ++k)
                std::swap(matrix[k * max_dimension + swapped], matrix[k * max_dimension + partner]);
            result = result == 0 ? 0 : modulus - result;
        }

        const auto first = pivot_index * max_dimension;
        const auto second = (pivot_index + 1) * max_dimension;
        const auto pivot = matrix[first + pivot_index + 1];
        result = multiply(result, pivot);
        const auto inverse = power(pivot, modulus - 2);
        for (std::size_t row = pivot_index + 2; row < dimension; ++row) {
            for (std::size_t column = row + 1; column < dimension; ++column) {
                const auto cross = normalize(
                    multiply(matrix[first + row], matrix[second + column])
                    - multiply(matrix[first + column], matrix[second + row]));
                const auto value = normalize(matrix[row * max_dimension + column]
                    - multiply(cross, inverse));
                matrix[row * max_dimension + column] = value;
                matrix[column * max_dimension + row] = value == 0 ? 0 : modulus - value;
            }
        }
    }
    return result;
}
