// Clean-room port of TSVC s123; see package README for provenance and rights.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s123_conditional_pair_expansion(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > 129) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;
    std::int64_t b[kMaxN], c[kMaxN], d[kMaxN], e[kMaxN], a[2 * kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        d[i] = input[1 + 2 * n + i];
        e[i] = input[1 + 3 * n + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
            d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100) return -1;
    }
    const auto required_bytes = 16 * n;
    if (output == nullptr || capacity < required_bytes) return -2;
    std::size_t j = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto product = d[i] * e[i];
        a[j++] = b[i] + product;
        if (c[i] > 0) a[j++] = c[i] + product;
    }
    for (std::size_t i = 0; i < j; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(j);
}
