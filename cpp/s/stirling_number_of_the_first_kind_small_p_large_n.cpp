#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t stirling_number_of_the_first_kind_small_p_large_n(
    const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::int64_t max_n = INT64_C(1000000000000000000);
    constexpr std::size_t max_t = 8;
    constexpr std::size_t max_k = 8;
    constexpr std::size_t width = 9;

    const auto is_prime = [](std::int64_t value) {
        if (value < 2) return false;
        for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
            if (value % divisor == 0) return false;
        }
        return true;
    };
    const auto stirling_value = [=](std::int64_t n, std::size_t k, std::int64_t modulus) {
        const auto quotient = n / modulus;
        const auto remainder = n % modulus;
        if (quotient > static_cast<std::int64_t>(k)) return std::int64_t{0};
        const auto target = k - static_cast<std::size_t>(quotient);
        std::array<std::int64_t, width> coefficients{};
        coefficients[0] = 1;
        for (std::int64_t residue = 0; residue < remainder; ++residue) {
            for (std::size_t degree = target; degree > 0; --degree) {
                coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus;
                if (coefficients[degree] < 0) coefficients[degree] += modulus;
            }
            coefficients[0] = (-residue * coefficients[0]) % modulus;
            if (coefficients[0] < 0) coefficients[0] += modulus;
        }
        const auto coefficient = coefficients[target];
        return quotient % 2 == 0 || coefficient == 0 ? coefficient : modulus - coefficient;
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
        const auto value = stirling_value(n, static_cast<std::size_t>(k_value), modulus);
        const auto next = static_cast<std::int64_t>(case_index + 1);
        result = (result + next * next * value) % modulus;
    }
    return result;
}
