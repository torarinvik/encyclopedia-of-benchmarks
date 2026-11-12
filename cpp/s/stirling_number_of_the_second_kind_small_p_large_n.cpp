#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t stirling_number_of_the_second_kind_small_p_large_n(
    const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::int64_t max_n = INT64_C(1000000000000000000);
    constexpr std::size_t max_t = 8;
    constexpr std::size_t max_k = 8;
    constexpr std::size_t width = 9;
    constexpr std::size_t cells = width * width;

    const auto is_prime = [](std::int64_t value) {
        if (value < 2) return false;
        for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
            if (value % divisor == 0) return false;
        }
        return true;
    };

    if (input == nullptr || length < 4 || length > 2 + 2 * max_t) return -1;
    const auto count_value = input[0];
    const auto modulus = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_t)
            || length != static_cast<std::size_t>(2 + 2 * count_value)
            || modulus < 11 || modulus > 97 || !is_prime(modulus)) return -1;

    std::int64_t result = 0;
    for (std::size_t case_index = 0; case_index < static_cast<std::size_t>(count_value); ++case_index) {
        const auto n = input[2 + 2 * case_index];
        const auto k_value = input[3 + 2 * case_index];
        if (n < 0 || n > max_n || k_value < 0 || k_value > static_cast<std::int64_t>(max_k) || k_value > n) return -1;
        const auto k = static_cast<std::size_t>(k_value);
        const auto dimension = k + 1;

        std::array<std::int64_t, cells> matrix{};
        std::array<std::int64_t, cells> squared{};
        std::array<std::int64_t, width> vector{};
        std::array<std::int64_t, width> next_vector{};
        for (std::size_t index = 0; index < dimension; ++index) {
            matrix[index * width + index] = static_cast<std::int64_t>(index) % modulus;
            if (index > 0) matrix[index * width + index - 1] = 1;
        }
        vector[0] = 1;
        auto exponent = n;
        while (exponent > 0) {
            if (exponent % 2 != 0) {
                for (std::size_t row = 0; row < dimension; ++row) {
                    std::int64_t total = 0;
                    for (std::size_t column = 0; column < dimension; ++column) {
                        total = (total + matrix[row * width + column] * vector[column]) % modulus;
                    }
                    next_vector[row] = total;
                }
                for (std::size_t row = 0; row < dimension; ++row) vector[row] = next_vector[row];
            }
            exponent /= 2;
            if (exponent > 0) {
                for (std::size_t row = 0; row < dimension; ++row) {
                    for (std::size_t column = 0; column < dimension; ++column) {
                        std::int64_t total = 0;
                        for (std::size_t inner = 0; inner < dimension; ++inner) {
                            total = (total + matrix[row * width + inner] * matrix[inner * width + column]) % modulus;
                        }
                        squared[row * width + column] = total;
                    }
                }
                for (std::size_t row = 0; row < dimension; ++row) {
                    for (std::size_t column = 0; column < dimension; ++column) {
                        matrix[row * width + column] = squared[row * width + column];
                        squared[row * width + column] = 0;
                    }
                }
            }
        }
        const auto weight = static_cast<std::int64_t>(case_index + 1) * static_cast<std::int64_t>(case_index + 1);
        result = (result + weight * vector[k]) % modulus;
    }
    return result;
}
