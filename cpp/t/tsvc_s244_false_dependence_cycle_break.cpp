// Clean-room port of TSVC s244; see package README for provenance and rights.
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

extern "C" std::int64_t tsvc_s244_false_dependence_cycle_break(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 9 || length > 129) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;
    std::int64_t a[kMaxN], b[kMaxN], c[kMaxN], d[kMaxN], trace[kMaxN - 1];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        c[i] = input[1 + 2 * n + i];
        d[i] = input[1 + 3 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2) return -1;
    }
    const auto output_values = 3 * n - 1;
    if (output == nullptr || capacity < 8 * output_values) return -2;
    for (std::size_t i = 0; i < n - 1; ++i) {
        a[i] = b[i] + c[i] * d[i];
        b[i] = c[i] + b[i];
        a[i + 1] = b[i] + a[i + 1] * d[i];
        trace[i] = a[i + 1];
    }
    std::size_t offset = 0;
    for (std::size_t i = 0; i < n; ++i, ++offset) store_i64_le(output, 8 * offset, a[i]);
    for (std::size_t i = 0; i < n; ++i, ++offset) store_i64_le(output, 8 * offset, b[i]);
    for (std::size_t i = 0; i < n - 1; ++i, ++offset) store_i64_le(output, 8 * offset, trace[i]);
    return static_cast<std::int64_t>(output_values);
}
