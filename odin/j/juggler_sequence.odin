package juggler_sequence

import "core:c"

floor_sqrt :: proc "contextless" (value: i64) -> i64 {
    low := i64(0)
    high := value + 1
    for high - low > 1 {
        middle := low + (high - low) / 2
        if middle <= value / middle do low = middle
        else do high = middle
    }
    return low
}

// Encode the Juggler sequence through its first 1 as little-endian u32 values.
@(export)
juggler_sequence :: proc "c" (value: i64, output: [^]u8,
        output_capacity: c.size_t) -> i64 {
    if value < 1 || value > 25 do return -1
    sequence: [16]i64
    count := c.size_t(1)
    sequence[0] = value
    for sequence[count - 1] != 1 {
        current := sequence[count - 1]
        if current % 2 == 0 do sequence[count] = floor_sqrt(current)
        else do sequence[count] = floor_sqrt(current * current * current)
        count += 1
    }
    required := count * 4
    if output == nil || output_capacity < required do return -2
    for index := c.size_t(0); index < count; index += 1 {
        term := u32(sequence[index])
        for byte := c.size_t(0); byte < 4; byte += 1 {
            output[4 * index + byte] = u8((term >> (8 * byte)) & 255)
        }
    }
    return i64(required)
}
