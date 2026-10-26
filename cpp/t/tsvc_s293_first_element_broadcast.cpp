// Clean-room implementation of TSVC s293; see package rights note.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
void store_i64_le(std::uint8_t *out, std::size_t pos, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[pos + b] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t tsvc_s293_first_element_broadcast(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 33) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) || length != 1 + static_cast<std::size_t>(input[0])) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 1; i < length; ++i) if (input[i] < -8 || input[i] > 8) return -1;
    const std::size_t bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    std::int64_t staged[max_n];
    for (std::size_t i = 0; i < n; ++i) staged[i] = input[1];
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(bytes);
}
