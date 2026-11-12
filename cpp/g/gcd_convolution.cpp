#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 128;
constexpr std::size_t kMaxInputLength = 1 + 2 * kMaxN + 1;
constexpr std::int64_t kModulus = 998244353;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void divisor_zeta(std::array<std::int64_t, kMaxN + 1>& values, int n) {
    for (int divisor = 1; divisor <= n; ++divisor)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[divisor] += values[multiple];
            if (values[divisor] >= kModulus) values[divisor] -= kModulus;
        }
}

void divisor_mobius(std::array<std::int64_t, kMaxN + 1>& values, int n) {
    for (int divisor = n; divisor >= 1; --divisor)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[divisor] -= values[multiple];
            if (values[divisor] < 0) values[divisor] += kModulus;
        }
}
} // namespace

extern "C" std::int64_t gcd_convolution(const std::int64_t* input, std::size_t length,
                                         std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > kMaxN) return -1;
    const int n = static_cast<int>(n_value);
    if (length != static_cast<std::size_t>(1 + 2 * n)) return -1;
    for (int index = 0; index < 2 * n; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= kModulus) return -1;

    const std::size_t output_bytes = 8 * static_cast<std::size_t>(n);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::int64_t, kMaxN + 1> a{};
    std::array<std::int64_t, kMaxN + 1> b{};
    std::array<std::int64_t, kMaxN + 1> c{};
    for (int index = 1; index <= n; ++index) {
        a[index] = input[index];
        b[index] = input[n + index];
    }
    divisor_zeta(a, n);
    divisor_zeta(b, n);
    for (int index = 1; index <= n; ++index)
        c[index] = (a[index] * b[index]) % kModulus;
    divisor_mobius(c, n);
    for (int index = 1; index <= n; ++index)
        store_i64_le(output, 8 * static_cast<std::size_t>(index - 1), c[index]);
    return static_cast<std::int64_t>(output_bytes);
}
