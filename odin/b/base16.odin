package base16

import "core:c"

@(export)
base16 :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 1 || length > 65 do return -1
    mode := input[0]
    if mode == 0 {
        count := length - 1
        output_length := count * 2
        for index := c.size_t(1); index < length; index += 1 {
            if input[index] < 0 || input[index] > 255 do return -1
        }
        if output_capacity < output_length do return -2
        for index := c.size_t(0); index < count; index += 1 {
            byte := input[index + 1]
            high, low := byte / 16, byte % 16
            if high < 10 { output[2 * index] = u8('0') + u8(high) }
            else { output[2 * index] = u8('A') + u8(high - 10) }
            if low < 10 { output[2 * index + 1] = u8('0') + u8(low) }
            else { output[2 * index + 1] = u8('A') + u8(low - 10) }
        }
        return i64(output_length)
    }
    if mode != 1 do return -1
    encoded_length := length - 1
    if encoded_length % 2 != 0 do return -1
    for index := c.size_t(1); index < length; index += 1 {
        byte := input[index]
        if !((byte >= i64('0') && byte <= i64('9')) || (byte >= i64('A') && byte <= i64('F'))) do return -1
    }
    output_length := encoded_length / 2
    if output_capacity < output_length do return -2
    for index := c.size_t(0); index < output_length; index += 1 {
        high_byte := input[1 + 2 * index]
        low_byte := input[2 + 2 * index]
        high := high_byte - i64('0')
        if high_byte >= i64('A') do high = high_byte - i64('A') + 10
        low := low_byte - i64('0')
        if low_byte >= i64('A') do low = low_byte - i64('A') + 10
        output[index] = u8(high * 16 + low)
    }
    return i64(output_length)
}
