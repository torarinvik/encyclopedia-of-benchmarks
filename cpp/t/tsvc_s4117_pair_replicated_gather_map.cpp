// Clean-room bounded port of TSVC s4117; see package README for provenance.
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

extern "C" std::int64_t tsvc_s4117_pair_replicated_gather_map(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 161) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto c_length = (n + 1) / 2;
    if (length != 1 + 2 * n + c_length) return -1;
    for (std::size_t i = 1; i < length; ++i) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    const auto b_offset = std::size_t{1};
    const auto c_offset = 1 + n;
    const auto d_offset = c_offset + c_length;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[b_offset + i] +
            input[c_offset + i / 2] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return static_cast<std::int64_t>(n);
}
