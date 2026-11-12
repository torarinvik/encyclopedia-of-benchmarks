#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t kModulus = 998244353;
constexpr std::size_t kMaxLength = 256;
constexpr std::size_t kMaxNttSize = 512;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxLength;

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % kModulus;
        base = base * base % kModulus;
        exponent >>= 1;
    }
    return result;
}

void transform(std::array<std::int64_t, kMaxNttSize>& values,
               std::size_t n, bool inverse) {
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1;
        for (; (j & bit) != 0; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(values[i], values[j]);
    }
    for (std::size_t stage = 2; stage <= n; stage <<= 1) {
        auto root = power_mod(3, (kModulus - 1) / static_cast<std::int64_t>(stage));
        if (inverse) root = power_mod(root, kModulus - 2);
        for (std::size_t start = 0; start < n; start += stage) {
            std::int64_t factor = 1;
            for (std::size_t offset = 0; offset < stage / 2; ++offset) {
                const auto left = values[start + offset];
                const auto right = values[start + offset + stage / 2] * factor % kModulus;
                values[start + offset] = (left + right) % kModulus;
                values[start + offset + stage / 2] = (left - right + kModulus) % kModulus;
                factor = factor * root % kModulus;
            }
        }
    }
    if (inverse) {
        const auto scale = power_mod(static_cast<std::int64_t>(n), kModulus - 2);
        for (std::size_t i = 0; i < n; ++i) values[i] = values[i] * scale % kModulus;
    }
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t convolution_mod(const std::int64_t* input,
                                         std::size_t length,
                                         std::uint8_t* output,
                                         std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 1 || n_value > 256 || m_value < 1 || m_value > 256) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= kModulus) return -1;

    const auto result_length = n + m - 1;
    std::size_t transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    const auto output_bytes = 8 * result_length;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<std::int64_t, kMaxNttSize> a{};
    std::array<std::int64_t, kMaxNttSize> b{};
    for (std::size_t i = 0; i < n; ++i) a[i] = input[2 + i];
    for (std::size_t i = 0; i < m; ++i) b[i] = input[2 + n + i];
    transform(a, transform_length, false);
    transform(b, transform_length, false);
    for (std::size_t i = 0; i < transform_length; ++i) a[i] = a[i] * b[i] % kModulus;
    transform(a, transform_length, true);
    for (std::size_t i = 0; i < result_length; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(output_bytes);
}
