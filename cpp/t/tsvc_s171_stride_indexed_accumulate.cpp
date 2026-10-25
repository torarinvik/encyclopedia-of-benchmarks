// Clean-room bounded port of TSVC s171; see package README for provenance.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxStride = 4;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s171_stride_indexed_accumulate(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 159) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(kMaxStride)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto stride = static_cast<std::size_t>(input[1]);
    const auto a_length = 1 + (n - 1) * stride;
    if (length != 2 + a_length + n) return -1;
    for (std::size_t i = 0; i < a_length + n; ++i) {
        if (input[2 + i] < -8 || input[2 + i] > 8) return -1;
    }
    if (output == nullptr || capacity < 8 * a_length) return -2;
    for (std::size_t i = 0; i < a_length; ++i) store_i64_le(output, 8 * i, input[2 + i]);
    const auto b_offset = 2 + a_length;
    for (std::size_t i = 0; i < n; ++i) {
        const auto destination = i * stride;
        store_i64_le(output, 8 * destination,
                     input[2 + destination] + input[b_offset + i]);
    }
    return static_cast<std::int64_t>(a_length);
}
