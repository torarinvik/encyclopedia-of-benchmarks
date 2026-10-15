// Encode the Juggler sequence through its first 1 as little-endian u32 values.
#include <cstddef>
#include <cstdint>

static std::int64_t floor_sqrt(std::int64_t value)
{
    std::int64_t low = 0, high = value + 1;
    while (high - low > 1) {
        const auto middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

extern "C" std::int64_t juggler_sequence(std::int64_t value, std::uint8_t *output,
                                          std::size_t output_capacity)
{
    if (value < 1 || value > 25) return -1;
    std::int64_t sequence[16];
    std::size_t count = 1;
    sequence[0] = value;
    while (sequence[count - 1] != 1) {
        const auto current = sequence[count - 1];
        sequence[count++] = current % 2 == 0 ? floor_sqrt(current)
            : floor_sqrt(current * current * current);
    }
    const auto required = count * 4;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto term = static_cast<std::uint32_t>(sequence[index]);
        for (unsigned byte = 0; byte < 4; ++byte)
            output[4 * index + byte] = static_cast<std::uint8_t>(term >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
