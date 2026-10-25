// Clean-room port of TSVC s453; see package README for provenance and rights.
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

extern "C" std::int64_t tsvc_s453_recurrence_weighted_scale(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 33) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n) return -1;
    std::int64_t b[kMaxN], a[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        if (b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    std::int64_t s = 0;
    for (std::size_t i = 0; i < n; ++i) {
        s += 2;
        a[i] = s * b[i];
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
