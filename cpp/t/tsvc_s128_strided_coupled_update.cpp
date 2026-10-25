// Clean-room port of TSVC s128; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 16;
constexpr std::size_t kMaxInputLength = 1 + 5 * kMaxN;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s128_strided_coupled_update(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto b_count = 2 * n;
    if (length != 1 + 5 * n) return -1;
    std::int64_t a[kMaxN], b[2 * kMaxN], c[2 * kMaxN], d[kMaxN];
    for (std::size_t i = 0; i < b_count; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + b_count + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100) return -1;
    }
    for (std::size_t i = 0; i < n; ++i) {
        d[i] = input[1 + 2 * b_count + i];
        if (d[i] < -100 || d[i] > 100) return -1;
    }
    const auto output_values = 3 * n;
    const auto output_bytes = 8 * output_values;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::int64_t j = -1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto k = static_cast<std::size_t>(j + 1);
        a[i] = b[k] - d[i];
        j = static_cast<std::int64_t>(k) + 1;
        b[k] = a[i] + c[k];
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    for (std::size_t i = 0; i < b_count; ++i) store_i64_le(output, 8 * (n + i), b[i]);
    return static_cast<std::int64_t>(output_values);
}
