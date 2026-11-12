#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxSize = std::size_t{1} << kMaxN;
constexpr std::size_t kMaxInputLength = 1 + 2 * kMaxSize;
constexpr std::int64_t kModulus = 998244353;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bitwise_and_convolution(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > 8) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto size = std::size_t{1} << n;
    if (length != 1 + 2 * size) return -1;
    for (std::size_t index = 0; index < 2 * size; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= kModulus) return -1;
    const auto output_bytes = 8 * size;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<std::int64_t, kMaxSize> a{};
    std::array<std::int64_t, kMaxSize> b{};
    for (std::size_t index = 0; index < size; ++index) {
        a[index] = input[1 + index];
        b[index] = input[1 + size + index];
    }
    for (std::size_t bit = 0; bit < n; ++bit) {
        const auto bit_mask = std::size_t{1} << bit;
        for (std::size_t mask = 0; mask < size; ++mask) {
            if ((mask & bit_mask) == 0) {
                a[mask] = (a[mask] + a[mask | bit_mask]) % kModulus;
                b[mask] = (b[mask] + b[mask | bit_mask]) % kModulus;
            }
        }
    }
    for (std::size_t mask = 0; mask < size; ++mask) a[mask] = (a[mask] * b[mask]) % kModulus;
    for (std::size_t bit = 0; bit < n; ++bit) {
        const auto bit_mask = std::size_t{1} << bit;
        for (std::size_t mask = 0; mask < size; ++mask) {
            if ((mask & bit_mask) == 0) {
                a[mask] -= a[mask | bit_mask];
                if (a[mask] < 0) a[mask] += kModulus;
            }
        }
    }
    for (std::size_t mask = 0; mask < size; ++mask)
        store_i64_le(output, 8 * mask, a[mask]);
    return static_cast<std::int64_t>(output_bytes);
}
