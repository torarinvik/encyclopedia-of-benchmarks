#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::int64_t max_exponent = INT64_C(1000000000000000000);
constexpr std::size_t max_n = 32;
constexpr std::size_t max_input = 34;
using Polynomial = std::array<std::int64_t, max_n>;

Polynomial multiply_truncated(const Polynomial& left, const Polynomial& right, std::size_t n) {
    Polynomial product{};
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n - i; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % modulus;
    return product;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t pow_of_formal_power_series(const std::int64_t* input,
                                                      std::size_t length,
                                                      std::uint8_t* output,
                                                      std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)
            || input[1] < 0 || input[1] > max_exponent) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 2) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= modulus) return -1;

    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    Polynomial result{};
    Polynomial base{};
    result[0] = 1;
    for (std::size_t i = 0; i < n; ++i) base[i] = input[i + 2];
    auto exponent = input[1];
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply_truncated(result, base, n);
        exponent >>= 1;
        if (exponent > 0) base = multiply_truncated(base, base, n);
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
