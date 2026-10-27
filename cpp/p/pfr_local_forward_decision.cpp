#include <cstddef>
#include <cstdint>

namespace {
void put64(std::uint8_t *out, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[i] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t pfr_local_forward_decision(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t angle = input[0], draw = input[1];
    if (angle < 0 || angle > 180000000 || draw < 0 || draw >= 1000000) return -1;
    const std::int64_t forward = angle >= 134000000 || 180 * draw < angle;
    if (output == nullptr || capacity < 8) return -2;
    put64(output, forward);
    return 8;
}
