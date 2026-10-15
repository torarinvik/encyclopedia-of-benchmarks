/* Decode and encode packed XS-3 digits using the pinned Java loop order. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t xs3_conversion(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length != 2) return -1;
    const std::int64_t direction = packed[0];
    std::int64_t value = packed[1];
    if (direction == 0) {
        if (value < 0 || value > INT32_MAX) return -1;
        std::int64_t decoded = 0;
        std::int64_t multiplier = 1;
        while (value > 0) {
            const std::int64_t nibble = value & 0xF;
            if (nibble < 3 || nibble > 12) return -1;
            decoded += (nibble - 3) * multiplier;
            multiplier *= 10;
            value >>= 4;
        }
        return decoded;
    }
    if (direction == 1) {
        if (value < 0 || value > 9999999) return -1;
        std::int64_t encoded = 0;
        unsigned shift = 0;
        while (value > 0) {
            const std::int64_t digit = value % 10 + 3;
            encoded |= digit << (shift * 4);
            value /= 10;
            ++shift;
        }
        return encoded;
    }
    return -1;
}
