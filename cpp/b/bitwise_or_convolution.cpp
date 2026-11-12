#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxSize = std::size_t{1} << kMaxN;
constexpr std::size_t kMaxInput = 1 + 2 * kMaxSize;
constexpr std::int64_t kMod = 998244353;
void store_i64_le(std::uint8_t *out, std::size_t pos, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[pos + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t bitwise_or_convolution(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const auto nv = input[0];
    if (nv < 0 || nv > 8) return -1;
    const auto n = static_cast<std::size_t>(nv), size = std::size_t{1} << n;
    if (length != 1 + 2 * size) return -1;
    for (std::size_t i = 0; i < 2 * size; ++i) if (input[1 + i] < 0 || input[1 + i] >= kMod) return -1;
    const auto bytes = 8 * size;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, kMaxSize> a{}, b{};
    for (std::size_t i = 0; i < size; ++i) { a[i] = input[1 + i]; b[i] = input[1 + size + i]; }
    for (std::size_t bit = 0; bit < n; ++bit) {
        const auto bit_mask = std::size_t{1} << bit;
        for (std::size_t mask = 0; mask < size; ++mask) if (mask & bit_mask) {
            a[mask] = (a[mask] + a[mask ^ bit_mask]) % kMod;
            b[mask] = (b[mask] + b[mask ^ bit_mask]) % kMod;
        }
    }
    for (std::size_t i = 0; i < size; ++i) a[i] = (a[i] * b[i]) % kMod;
    for (std::size_t bit = 0; bit < n; ++bit) {
        const auto bit_mask = std::size_t{1} << bit;
        for (std::size_t mask = 0; mask < size; ++mask) if (mask & bit_mask) {
            a[mask] -= a[mask ^ bit_mask];
            if (a[mask] < 0) a[mask] += kMod;
        }
    }
    for (std::size_t i = 0; i < size; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(bytes);
}
