// Lucas-based closed form for repeated -(left + right) mod 3 reduction.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxN = 256;

std::int64_t binomial_mod_three(std::int64_t n, std::int64_t k) noexcept {
    std::int64_t coefficient = 1;
    while (n > 0 || k > 0) {
        const auto n_digit = n % 3;
        const auto k_digit = k % 3;
        if (k_digit > n_digit) return 0;
        if (n_digit == 2 && k_digit == 1) coefficient = (2 * coefficient) % 3;
        n /= 3;
        k /= 3;
    }
    return coefficient;
}
} // namespace

extern "C" std::int64_t coloured_triangle_reduction(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 258) return -1;
    const std::int64_t n = input[0];
    if (n < 1 || n > kMaxN || length != static_cast<std::size_t>(n + 1)) return -1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(n); ++index)
        if (input[index + 1] < 0 || input[index + 1] > 2) return -1;

    const std::int64_t rounds = n - 1;
    std::int64_t total = 0;
    for (std::int64_t index = 0; index < n; ++index)
        total = (total + binomial_mod_three(rounds, index) * input[index + 1]) % 3;
    return rounds % 2 == 0 ? total : (3 - total) % 3;
}
