package duplicate_zeros

import "core:c"

write_i32 :: proc "contextless" (output: [^]u8, position: c.size_t, value: i64) {
    encoded := value
    if encoded < 0 { encoded += 4294967296 }
    output[position] = u8(encoded % 256)
    output[position + 1] = u8((encoded / 256) % 256)
    output[position + 2] = u8((encoded / 65536) % 256)
    output[position + 3] = u8(encoded / 16777216)
}

// Duplicate each zero while retaining the fixed output length.
@(export)
duplicate_zeros :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 64 do return -1
    for index: c.size_t = 0; index < length; index += 1 {
        if values[index] < 0 || values[index] > 1000 do return -1
    }
    required := 4 * length
    if output_capacity < required || (required > 0 && output == nil) do return -2
    source, destination := c.size_t(0), c.size_t(0)
    for destination < length {
        value := values[source]
        source += 1
        write_i32(output, 4 * destination, value)
        destination += 1
        if value == 0 && destination < length {
            write_i32(output, 4 * destination, 0)
            destination += 1
        }
    }
    return i64(length)
}
