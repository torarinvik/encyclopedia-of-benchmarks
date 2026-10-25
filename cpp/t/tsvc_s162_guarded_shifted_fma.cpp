// Clean-room bounded port of TSVC s162; see package README for provenance.
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

extern "C" std::int64_t tsvc_s162_guarded_shifted_fma(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > 194) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 0 || input[1] > 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 2 + 3 * n) return -1;
    for (std::size_t i = 2; i < length; ++i) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    const auto a_offset = std::size_t{2};
    const auto b_offset = a_offset + n;
    const auto c_offset = b_offset + n;
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, input[a_offset + i]);
    if (input[1] > 0) {
        for (std::size_t i = 0; i + 1 < n; ++i) {
            const auto value = input[a_offset + i + 1] +
                input[b_offset + i] * input[c_offset + i];
            store_i64_le(output, 8 * i, value);
        }
    }
    return static_cast<std::int64_t>(n);
}
