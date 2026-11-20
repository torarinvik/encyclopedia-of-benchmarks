#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_words = 5;
constexpr std::size_t max_words = 16;
constexpr std::size_t output_bytes = 16;

std::int64_t gcd_positive(std::int64_t a, std::int64_t b) noexcept {
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

void store_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t levin_partial_sum_transform(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < min_words || input_length > max_words) return -1;
    const auto n0 = input[0], k0 = input[1];
    if (n0 < 0 || n0 > 8 || k0 < 1 || k0 > 3) return -1;
    const auto n = static_cast<std::size_t>(n0), k = static_cast<std::size_t>(k0);
    if (input_length != n + k + 4) return -1;
    const auto term_count = n + k + 2;
    for (std::size_t i = 0; i < term_count; ++i)
        if (input[i + 2] == 0 || input[i + 2] < -3 || input[i + 2] > 3) return -1;

    std::int64_t product = 1;
    for (std::size_t j = 0; j <= k; ++j) product *= input[n + j + 3];
    std::int64_t numerator = 0, denominator = 0;
    for (std::size_t j = 0; j <= k; ++j) {
        std::int64_t choose = 1;
        for (std::size_t r = 1; r <= j; ++r)
            choose = choose * static_cast<std::int64_t>(k - r + 1) / static_cast<std::int64_t>(r);
        std::int64_t power = 1;
        for (std::size_t exponent = 0; exponent < k - 1; ++exponent)
            power *= static_cast<std::int64_t>(n + j + 1);
        const auto term = input[n + j + 3];
        auto weight = choose * power * (product / term);
        if (j & 1u) weight = -weight;
        std::int64_t partial = 0;
        for (std::size_t index = 0; index <= n + j; ++index) partial += input[index + 2];
        numerator += weight * partial;
        denominator += weight;
    }
    if (denominator == 0) return -1;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    const auto divisor = gcd_positive(numerator < 0 ? -numerator : numerator, denominator);
    numerator /= divisor;
    denominator /= divisor;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    store_i64(output, 0, numerator);
    store_i64(output, 8, denominator);
    return output_bytes;
}
