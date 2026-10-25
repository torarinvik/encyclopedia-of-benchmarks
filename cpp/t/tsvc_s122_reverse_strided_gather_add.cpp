// Clean-room port of TSVC s122; see package README for provenance and rights.
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

extern "C" std::int64_t tsvc_s122_reverse_strided_gather_add(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > 67) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input[1] < 1 || input[1] > static_cast<std::int64_t>(n) ||
        input[2] < 1 || input[2] > static_cast<std::int64_t>(n)) return -1;
    if (length != 3 + 2 * n) return -1;
    const auto start = static_cast<std::size_t>(input[1]);
    const auto stride = static_cast<std::size_t>(input[2]);
    std::int64_t a[kMaxN], b[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[3 + i];
        b[i] = input[3 + n + i];
        if (a[i] < -100 || a[i] > 100 || b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    std::int64_t j = 1, k = 0;
    for (std::size_t i = start - 1; i < n; i += stride) {
        k += j;
        a[i] += b[n - static_cast<std::size_t>(k)];
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
