package gray_code

import "core:c"

// Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
@(export)
gray_code :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length != 1 || input[0] < 0 || input[0] > 13 do return -1
    bit_count := int(input[0])
    count := c.size_t(0)
    if bit_count > 0 do count = c.size_t(1) << bit_count
    required := count * 4
    if output == nil || output_capacity < required do return -2
    for index := c.size_t(0); index < count; index += 1 {
        gray := u32(index ^ (index >> 1))
        for byte := c.size_t(0); byte < 4; byte += 1 {
            output[4 * index + byte] = u8((gray >> (8 * byte)) & 255)
        }
    }
    return i64(count)
}
