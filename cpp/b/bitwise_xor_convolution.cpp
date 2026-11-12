#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxSize = std::size_t{1} << kMaxN;
constexpr std::size_t kMaxInput = 1 + 2 * kMaxSize;
constexpr std::int64_t kModulus = 998244353;

void xor_walsh_transform(std::array<std::int64_t, kMaxSize>& values, std::size_t size) {
    for (std::size_t half = 1; half < size; half *= 2) {
        for (std::size_t block = 0; block < size; block += 2 * half) {
            for (std::size_t offset = 0; offset < half; ++offset) {
                const auto left = values[block + offset];
                const auto right = values[block + half + offset];
                values[block + offset] = (left + right) % kModulus;
                values[block + half + offset] = (left - right + kModulus) % kModulus;
            }
        }
    }
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bitwise_xor_convolution(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 1 || length > kMaxInput) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto size = std::size_t{1} << n;
    if (length != 1 + 2 * size) return -1;
    for (std::size_t index = 0; index < 2 * size; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= kModulus) return -1;

    const auto output_bytes = 8 * size;
    if (!output || capacity < output_bytes) return -2;
    std::array<std::int64_t, kMaxSize> first{};
    std::array<std::int64_t, kMaxSize> second{};
    for (std::size_t index = 0; index < size; ++index) {
        first[index] = input[1 + index];
        second[index] = input[1 + size + index];
    }
    xor_walsh_transform(first, size);
    xor_walsh_transform(second, size);
    for (std::size_t index = 0; index < size; ++index)
        first[index] = (first[index] * second[index]) % kModulus;
    xor_walsh_transform(first, size);

    std::int64_t inverse_size = 1;
    for (std::size_t bit = 0; bit < n; ++bit)
        inverse_size = (inverse_size * ((kModulus + 1) / 2)) % kModulus;
    for (std::size_t index = 0; index < size; ++index)
        store_i64_le(output, 8 * index, (first[index] * inverse_size) % kModulus);
    return static_cast<std::int64_t>(output_bytes);
}
