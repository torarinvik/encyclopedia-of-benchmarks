// Clean-room bounded port of TSVC s252; see package README for provenance.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s252_adjacent_product_pair_sum(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 129) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    std::int64_t b[kMaxN], c[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        if (b[i] < -2 || b[i] > 2 || c[i] < -2 || c[i] > 2) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    std::int64_t previous_product = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto product = b[i] * c[i];
        store_i64_le(output, 8 * i, product + previous_product);
        previous_product = product;
    }
    return static_cast<std::int64_t>(n);
}
