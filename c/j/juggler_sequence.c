/* Encode the Juggler sequence through its first 1 as little-endian u32 values. */
#include <stddef.h>
#include <stdint.h>

static int64_t floor_sqrt(int64_t value)
{
    int64_t low = 0, high = value + 1;
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

int64_t juggler_sequence(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > 25) return -1;
    int64_t sequence[16];
    size_t count = 1;
    sequence[0] = value;
    while (sequence[count - 1] != 1) {
        const int64_t current = sequence[count - 1];
        sequence[count++] = current % 2 == 0 ? floor_sqrt(current)
            : floor_sqrt(current * current * current);
    }
    const size_t required = count * 4;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < count; ++index) {
        const uint32_t term = (uint32_t)sequence[index];
        for (unsigned byte = 0; byte < 4; ++byte)
            output[4 * index + byte] = (uint8_t)(term >> (8 * byte));
    }
    return (int64_t)required;
}
