#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_modulus = 31;
constexpr std::size_t max_t = 16;
constexpr std::size_t max_n = 16;
constexpr std::size_t max_parseable_input_length = 36;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t modular_power(std::int64_t base, std::size_t exponent,
                           std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1U) != 0U) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
} // namespace

extern "C" std::int64_t q_binomial_coefficient_prime_mod(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable_input_length) {
        return -1;
    }
    const auto count_value = input[0];
    const auto modulus = input[1];
    const auto q_value = input[2];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_t)
        || modulus < 2 || modulus > max_modulus || !is_prime(modulus)
        || q_value < 0 || q_value >= modulus) {
        return -1;
    }
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 3 + 2 * count) return -1;

    std::size_t max_n = 0;
    for (std::size_t query = 0; query < count; ++query) {
        const auto n_value = input[3 + 2 * query];
        const auto k_value = input[4 + 2 * query];
        if (n_value < 0 || n_value > 16 || k_value < 0 || k_value > 16
            || n_value >= modulus || k_value >= modulus) {
            return -1;
        }
        if (static_cast<std::size_t>(n_value) > max_n) {
            max_n = static_cast<std::size_t>(n_value);
        }
    }
    if (output == nullptr || capacity < count) return -2;

    std::int64_t table[17][17]{};
    table[0][0] = 1;
    for (std::size_t n = 1; n <= max_n; ++n) {
        table[n][0] = 1;
        for (std::size_t k = 1; k <= n; ++k) {
            const auto previous_same = k < n ? table[n - 1][k] : 0;
            const auto weight = modular_power(q_value, n - k, modulus);
            table[n][k] = (previous_same + weight * table[n - 1][k - 1])
                % modulus;
        }
    }
    for (std::size_t query = 0; query < count; ++query) {
        const auto n = static_cast<std::size_t>(input[3 + 2 * query]);
        const auto k = static_cast<std::size_t>(input[4 + 2 * query]);
        output[query] = static_cast<std::uint8_t>(k > n ? 0 : table[n][k]);
    }
    return static_cast<std::int64_t>(count);
}
