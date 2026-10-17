#include <cstddef>
#include <cstdint>

extern "C" std::int64_t long_utils(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    if (input[0] < 0 || input[0] > 3 || input[2] < 0 || input[2] > 63) return -1;
    if (output == nullptr || capacity < 8) return -2;
    const auto bits = static_cast<std::uint64_t>(input[1]);
    const unsigned distance = static_cast<unsigned>(input[2]);
    std::uint64_t rotated = bits;
    if (distance != 0) {
        if (input[0] < 2) rotated = (bits << distance) | (bits >> (64 - distance));
        else rotated = (bits >> distance) | (bits << (64 - distance));
    }
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(rotated >> (8 * byte));
    return 8;
}
