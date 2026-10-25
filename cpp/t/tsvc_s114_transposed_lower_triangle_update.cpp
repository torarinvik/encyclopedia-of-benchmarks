// Clean-room port of TSVC s114; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 16;
constexpr std::size_t kMaxInputLength = 1 + 2 * kMaxN * kMaxN;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s114_transposed_lower_triangle_update(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 9 || length > kMaxInputLength) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    std::int64_t a[kMaxN * kMaxN], b[kMaxN * kMaxN];
    for (std::size_t i = 0; i < cells; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + cells + i];
        if (a[i] < -1'000'000 || a[i] > 1'000'000 || b[i] < -1'000'000 || b[i] > 1'000'000) return -1;
    }
    const auto output_bytes = 8 * cells;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < i; ++j)
            a[i * n + j] = a[j * n + i] + b[i * n + j];
    for (std::size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(cells);
}
