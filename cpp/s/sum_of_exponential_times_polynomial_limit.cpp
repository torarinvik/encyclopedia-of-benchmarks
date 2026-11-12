// Infinite geometric-weighted power sum via an Eulerian polynomial row.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_degree = 256;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t sum_of_exponential_times_polynomial_limit(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t r = input[0];
    const std::int64_t degree_value = input[1];
    if (r < 0 || r >= modulus || r == 1 || degree_value < 0 || degree_value > static_cast<std::int64_t>(max_degree)) return -1;
    const auto degree = static_cast<std::size_t>(degree_value);
    const std::int64_t denominator = (1 - r + modulus) % modulus;
    const std::int64_t inverse = mod_pow(denominator, modulus - 2);
    if (degree == 0) return inverse;

    std::int64_t row[max_degree + 1]{};
    std::int64_t next[max_degree + 1]{};
    row[0] = 1;
    for (std::size_t n = 1; n <= degree; ++n) {
        for (std::size_t k = 0; k <= n; ++k) {
            std::int64_t value = 0;
            if (k > 0) value += static_cast<std::int64_t>(n - k) * row[k - 1];
            if (k < n) value += static_cast<std::int64_t>(k + 1) * row[k];
            next[k] = value % modulus;
        }
        for (std::size_t k = 0; k <= n; ++k) {
            row[k] = next[k];
            next[k] = 0;
        }
    }

    std::int64_t eulerian_value = 0;
    for (std::size_t k = degree; k > 0; --k) {
        eulerian_value = (eulerian_value * r + row[k - 1]) % modulus;
    }
    const std::int64_t denominator_power = mod_pow(inverse, static_cast<std::int64_t>(degree) + 1);
    return r * eulerian_value % modulus * denominator_power % modulus;
}
