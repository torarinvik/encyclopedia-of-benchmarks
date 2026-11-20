#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_words = 11;
constexpr std::size_t table_columns = 9;

std::int64_t mod(std::int64_t value) noexcept {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::int64_t multiply(std::int64_t left, std::int64_t right) noexcept {
    return (left * right) % modulus;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

void store_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t stieltjes_quotient_difference_transform(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 || input_length > max_words) return -1;
    const auto n0 = input[0];
    if (n0 < 2 || n0 > 9 || input_length != static_cast<std::size_t>(n0 + 1)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] <= 0 || input[i + 1] >= modulus) return -1;

    std::int64_t q[5][table_columns]{};
    std::int64_t e[5][table_columns]{};
    for (std::size_t k = 0; k + 1 < n; ++k)
        q[1][k] = multiply(input[k + 2], power(input[k + 1], modulus - 2));

    for (int j = 1; j <= 4; ++j) {
        const int last_e = static_cast<int>(n) - 2 * j - 1;
        if (last_e < 0) break;
        for (int k = 0; k <= last_e; ++k)
            e[j][k] = mod(e[j - 1][k + 1] + q[j][k + 1] - q[j][k]);
        const int last_q = static_cast<int>(n) - 2 * j - 2;
        if (last_q >= 0) {
            for (int k = 0; k <= last_q; ++k) {
                const auto pivot = e[j][k];
                if (pivot == 0) return -1;
                const auto product = multiply(q[j][k + 1], e[j][k + 1]);
                q[j + 1][k] = multiply(product, power(pivot, modulus - 2));
            }
        }
    }

    const std::size_t required = 8 * (n + 1);
    if (output == nullptr || output_capacity < required) return -2;
    store_i64(output, 0, static_cast<std::int64_t>(n));
    for (std::size_t index = 1; index < n; ++index) {
        const auto row = static_cast<int>((index + 1) / 2);
        const auto value = (index & 1) ? q[row][0] : e[index / 2][0];
        store_i64(output, 8 * index, value);
    }
    return static_cast<std::int64_t>(required);
}
