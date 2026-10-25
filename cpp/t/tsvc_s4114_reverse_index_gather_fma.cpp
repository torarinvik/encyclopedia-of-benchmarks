// Clean-room bounded port of TSVC s4114; see package README for provenance.
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

extern "C" std::int64_t tsvc_s4114_reverse_index_gather_fma(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > 257) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;
    const auto ip_offset = std::size_t{1}, b_offset = 1 + n;
    const auto c_offset = 1 + 2 * n, d_offset = 1 + 3 * n;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[ip_offset + i] < 0 || input[ip_offset + i] >= static_cast<std::int64_t>(n)) return -1;
        if (input[b_offset + i] < -2 || input[b_offset + i] > 2 ||
            input[c_offset + i] < -2 || input[c_offset + i] > 2 ||
            input[d_offset + i] < -2 || input[d_offset + i] > 2) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto gathered = n - 1 - static_cast<std::size_t>(input[ip_offset + i]);
        const auto value = input[b_offset + i] + input[c_offset + gathered] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return static_cast<std::int64_t>(n);
}
