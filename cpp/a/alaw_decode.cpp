#include <cstdint>

extern "C" std::int64_t alaw_decode(std::int64_t input) noexcept {
    if (input < 0 || input > 255) return -1;

    const std::int32_t alaw = static_cast<std::int32_t>(input) ^ 0xD5;
    const std::int32_t sign = alaw & 0x80;
    const std::int32_t segment = (alaw & 0x70) >> 4;
    std::int32_t sample = ((alaw & 0x0F) << 4) | 8;
    if (segment != 0) sample += 0x100;
    const std::int32_t shift = segment > 1 ? segment - 1 : 0;
    sample <<= shift;
    return sign != 0 ? -sample : sample;
}
