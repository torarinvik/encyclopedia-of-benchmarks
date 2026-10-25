// Clean-room port of TSVC s1221; see package README for provenance and rights.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMinN = 5;
constexpr std::size_t kMaxN = 32;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s1221_lag4_add_recurrence(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 11 || length > 65) return -1;
    if (input[0] < static_cast<std::int64_t>(kMinN) ||
        input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    std::int64_t a[kMaxN], b[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        if (a[i] < -10 || a[i] > 10 || b[i] < -10 || b[i] > 10) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    for (std::size_t i = 4; i < n; ++i) b[i] = b[i - 4] + a[i];
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, b[i]);
    return static_cast<std::int64_t>(n);
}
