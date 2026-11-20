#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 64;
constexpr std::size_t max_input_words = 66;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t blelloch_parallel_prefix_scan(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_items)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    if (length != n + 1) return -1;

    std::array<std::int64_t, max_items> tree{};
    std::size_t padded = 1;
    while (padded < n) padded <<= 1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value < -1'000'000 || value > 1'000'000) return -1;
        tree[i] = value;
    }
    if (output == nullptr || output_capacity < n * 8) return -2;

    for (std::size_t stride = 2; stride <= padded; stride <<= 1) {
        const auto half = stride >> 1;
        for (std::size_t right = stride - 1; right < padded; right += stride)
            tree[right] += tree[right - half];
    }
    tree[padded - 1] = 0;
    for (std::size_t stride = padded; stride >= 2; stride >>= 1) {
        const auto half = stride >> 1;
        for (std::size_t right = stride - 1; right < padded; right += stride) {
            const auto left = right - half;
            const auto partial = tree[left];
            tree[left] = tree[right];
            tree[right] += partial;
        }
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, i * 8, tree[i]);
    return static_cast<std::int64_t>(n * 8);
}
