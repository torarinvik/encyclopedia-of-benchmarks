/* Duplicate each zero while retaining the fixed output length. */
#include <cstddef>
#include <cstdint>

static void write_i32(std::uint8_t *output, std::size_t position, std::int32_t value)
{
    const auto encoded = static_cast<std::uint32_t>(value);
    output[position] = static_cast<std::uint8_t>(encoded);
    output[position + 1] = static_cast<std::uint8_t>(encoded >> 8);
    output[position + 2] = static_cast<std::uint8_t>(encoded >> 16);
    output[position + 3] = static_cast<std::uint8_t>(encoded >> 24);
}

extern "C" std::int64_t duplicate_zeros(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > 64) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 1000) return -1;
    const auto required = 4 * length;
    if (output_capacity < required || (required > 0 && output == nullptr)) return -2;
    std::size_t source = 0, destination = 0;
    while (destination < length) {
        const auto value = values[source++];
        write_i32(output, 4 * destination++, static_cast<std::int32_t>(value));
        if (value == 0 && destination < length) write_i32(output, 4 * destination++, 0);
    }
    return static_cast<std::int64_t>(length);
}
