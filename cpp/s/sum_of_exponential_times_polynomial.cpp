// Finite geometric power sum by binary composition of moment blocks.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_degree = 32;
using Moments = std::array<std::int64_t, max_degree + 1>;
using Binomials = std::array<std::array<std::int64_t, max_degree + 1>, max_degree + 1>;

Moments shift_moments(const Moments &source, std::uint64_t shift, std::size_t degree,
                      const Binomials &choose) {
    Moments powers{};
    Moments destination{};
    powers[0] = 1;
    const auto reduced_shift = static_cast<std::int64_t>(shift % static_cast<std::uint64_t>(modulus));
    for (std::size_t i = 1; i <= degree; ++i) powers[i] = powers[i - 1] * reduced_shift % modulus;
    for (std::size_t d = 0; d <= degree; ++d) {
        std::int64_t total = 0;
        for (std::size_t k = 0; k <= d; ++k) {
            const auto term = choose[d][k] * powers[d - k] % modulus;
            total = (total + term * source[k]) % modulus;
        }
        destination[d] = total;
    }
    return destination;
}
}

extern "C" std::int64_t sum_of_exponential_times_polynomial(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 3) return -1;
    const auto r = input[0], degree_value = input[1], n_value = input[2];
    if (r < 0 || r >= modulus || degree_value < 0 || degree_value > static_cast<std::int64_t>(max_degree) ||
        n_value < 0 || n_value > INT64_C(1000000000000000000)) return -1;
    const auto degree = static_cast<std::size_t>(degree_value);
    Binomials choose{};
    choose[0][0] = 1;
    for (std::size_t d = 1; d <= degree; ++d) {
        choose[d][0] = choose[d][d] = 1;
        for (std::size_t k = 1; k < d; ++k) choose[d][k] = (choose[d - 1][k - 1] + choose[d - 1][k]) % modulus;
    }

    Moments accumulated{}, block{};
    block[0] = 1;
    std::int64_t accumulated_power = 1, block_power = r;
    std::uint64_t accumulated_length = 0, block_length = 1, remaining = static_cast<std::uint64_t>(n_value);
    while (remaining > 0) {
        if ((remaining & 1U) != 0) {
            const auto shifted = shift_moments(block, accumulated_length, degree, choose);
            for (std::size_t d = 0; d <= degree; ++d)
                accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % modulus;
            accumulated_power = accumulated_power * block_power % modulus;
            accumulated_length += block_length;
        }
        const auto shifted = shift_moments(block, block_length, degree, choose);
        for (std::size_t d = 0; d <= degree; ++d)
            block[d] = (block[d] + block_power * shifted[d]) % modulus;
        block_power = block_power * block_power % modulus;
        block_length <<= 1;
        remaining >>= 1;
    }
    return accumulated[degree];
}
