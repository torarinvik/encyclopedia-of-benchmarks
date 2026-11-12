#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_t = 16;
constexpr std::size_t max_n = 128;
constexpr std::size_t max_input = 34;
}

extern "C" std::int64_t prefix_sum_of_binomial_coefficient(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_t)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;
    std::int64_t n[max_t], k[max_t];
    for (std::size_t query = 0; query < count; ++query) {
        n[query] = input[1 + 2 * query];
        k[query] = input[2 + 2 * query];
        if (n[query] < 0 || n[query] > static_cast<std::int64_t>(max_n) ||
            k[query] < 0 || k[query] > n[query]) return -1;
    }
    const auto output_length = 4 * count;
    if (output == nullptr || capacity < output_length) return -2;

    std::int64_t inverse[max_n + 1]{};
    inverse[1] = 1;
    for (std::size_t value = 2; value <= max_n; ++value) {
        inverse[value] = modulus - (modulus / static_cast<std::int64_t>(value)) *
            inverse[modulus % static_cast<std::int64_t>(value)] % modulus;
    }
    for (std::size_t query = 0; query < count; ++query) {
        std::int64_t coefficient = 1, prefix = 1;
        for (std::int64_t index = 0; index < k[query]; ++index) {
            coefficient = coefficient * (n[query] - index) % modulus;
            coefficient = coefficient * inverse[index + 1] % modulus;
            prefix = (prefix + coefficient) % modulus;
        }
        const auto residue = static_cast<std::uint32_t>(prefix);
        const auto offset = 4 * query;
        output[offset] = static_cast<std::uint8_t>(residue);
        output[offset + 1] = static_cast<std::uint8_t>(residue >> 8);
        output[offset + 2] = static_cast<std::uint8_t>(residue >> 16);
        output[offset + 3] = static_cast<std::uint8_t>(residue >> 24);
    }
    return static_cast<std::int64_t>(output_length);
}
