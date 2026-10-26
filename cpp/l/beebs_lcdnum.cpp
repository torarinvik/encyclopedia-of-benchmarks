/* Clean-room bounded digit-to-segment profile for the BEEBS lcdnum source. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t INPUT_BYTES = 5;
constexpr std::size_t OUTPUT_BYTES = 5;
constexpr std::uint8_t SEGMENT_MASKS[16] = {
    0x00, 0x24, 0x5D, 0x6D, 0x2E, 0x5D, 0x7B, 0x25,
    0x7F, 0x6F, 0x3F, 0x7A, 0x53, 0x7C, 0x5B, 0x1B
};
}

extern "C" std::int64_t beebs_lcdnum(const std::int64_t *values, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length != INPUT_BYTES) return -1;
    for (std::size_t i = 0; i < INPUT_BYTES; ++i)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (output == nullptr || capacity < OUTPUT_BYTES) return -2;
    for (std::size_t i = 0; i < INPUT_BYTES; ++i)
        output[i] = SEGMENT_MASKS[static_cast<std::uint8_t>(values[i]) & 0x0F];
    return OUTPUT_BYTES;
}
