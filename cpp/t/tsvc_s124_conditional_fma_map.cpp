// Clean-room port of TSVC s124; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxInputLength = 1 + 4 * kMaxN;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s124_conditional_fma_map(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;
    std::int64_t a[kMaxN], b[kMaxN], c[kMaxN], d[kMaxN], e[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        d[i] = input[1 + 2 * n + i];
        e[i] = input[1 + 3 * n + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
            d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    std::int64_t j = -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (b[i] > 0) {
            ++j;
            a[static_cast<std::size_t>(j)] = b[i] + d[i] * e[i];
        } else {
            ++j;
            a[static_cast<std::size_t>(j)] = c[i] + d[i] * e[i];
        }
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
