#include <cstddef>
#include <cstdint>

namespace {
std::int64_t hex_nibble(std::int64_t value) {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    return -1;
}
}

extern "C" std::int64_t hex_to_rgb(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 6) return -1;
    std::int64_t packed_rgb = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto nibble = hex_nibble(input[index]);
        if (nibble < 0) return -1;
        packed_rgb = (packed_rgb << 4) | nibble;
    }
    return packed_rgb;
}
