// Clean-room bounded port of TSVC s332; see package README for provenance.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 256;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s332_first_above_threshold(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > 258) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < -1000000 || input[1] > 1000000) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto threshold = input[1];
    if (length != 2 + n) return -1;
    std::int64_t values[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        values[i] = input[2 + i];
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    }
    if (output == nullptr || capacity < 16) return -2;
    std::int64_t index = -2, value = -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (values[i] > threshold) {
            index = static_cast<std::int64_t>(i);
            value = values[i];
            break;
        }
    }
    store_i64_le(output, 0, index);
    store_i64_le(output, 8, value);
    return 2;
}
