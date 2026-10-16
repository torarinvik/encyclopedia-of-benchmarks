// Portable byte-channel negative transform.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t convert_to_negative(const std::int64_t *values, std::size_t length,
                                            std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 1 || length > 4096) return -1;
    const std::int64_t count = values[0];
    if (count < 0 || count > 4095 || static_cast<std::size_t>(count) != length - 1) return -1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index)
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    if (static_cast<std::size_t>(count) > output_capacity || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index)
        output[index] = static_cast<std::uint8_t>(255 - values[index + 1]);
    return count;
}
