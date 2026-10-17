package lsb_image_steganography

import "core:c"

@(export)
lsb_image_steganography :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 292 do return -1
    if input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 32 do return -1
    rows, columns, message_length := int(input[0]), int(input[1]), int(input[2])
    pixel_count := rows * columns
    if message_length * 8 > pixel_count || length != c.size_t(3 + pixel_count + message_length) do return -1
    for i := 0; i < pixel_count; i += 1 {
        if input[3 + i] < 0 || input[3 + i] > 254 do return -1
    }
    for i := 0; i < message_length; i += 1 {
        if input[3 + pixel_count + i] < 0 || input[3 + pixel_count + i] > 127 do return -1
    }
    if output == nil || output_capacity < c.size_t(pixel_count) do return -2
    for i := 0; i < pixel_count; i += 1 { output[i] = u8(input[3 + i]) }
    bit_index := 0
    for i := 0; i < message_length; i += 1 {
        byte := u8(input[3 + pixel_count + i])
        for shift := 7; shift >= 0; shift -= 1 {
            bit := (byte >> u8(shift)) & 1
            pixel := output[bit_index]
            output[bit_index] = pixel + ((pixel & 1) ^ bit)
            bit_index += 1
        }
    }
    return i64(pixel_count)
}
