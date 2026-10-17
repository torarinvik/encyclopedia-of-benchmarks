package pkcs7_padding

import "core:c"

@(export)
pkcs7_padding :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > 69 do return -1
    operation, block_arg, offset_arg, data_arg := input[0], input[1], input[2], input[3]
    if operation < 0 || operation > 2 || block_arg < 1 || block_arg > 16 ||
        data_arg < 1 || data_arg > 64 ||
        (operation == 0 && (offset_arg < 0 || offset_arg > data_arg)) ||
        length != c.size_t(data_arg) + 4 do return -1
    block_size, data_length := c.size_t(block_arg), c.size_t(data_arg)
    offset := c.size_t(0)
    if operation == 0 { offset = c.size_t(offset_arg) }
    for index := c.size_t(0); index < data_length; index += 1 {
        if input[4 + index] < 0 || input[4 + index] > 255 do return -1
    }

    padding_count, output_length: c.size_t
    if operation == 0 {
        padding_count = block_size - data_length % block_size
        if offset + padding_count > data_length do return -1
        output_length = data_length + 1
    } else if operation == 1 {
        if data_length % block_size != 0 do return -1
        padding_count = c.size_t(input[3 + data_length])
        if padding_count == 0 || padding_count > block_size do return -1
        for index := data_length - padding_count; index < data_length; index += 1 {
            if c.size_t(input[4 + index]) != padding_count do return -1
        }
        output_length = data_length - padding_count
    } else {
        padding_count = c.size_t(input[3 + data_length])
        padding_start := i64(data_length) - i64(padding_count)
        invalid_bits := padding_start | (i64(padding_count) - 1)
        padding_check_failed := -i64(u32(invalid_bits) >> 31)
        for index := c.size_t(0); index < data_length; index += 1 {
            difference := i64(index) - padding_start
            negative_bit := u32(difference) >> 31
            mask := -i64(1 - negative_bit)
            padding_check_failed |= (input[4 + index] ^ i64(padding_count)) & mask
        }
        if padding_check_failed != 0 do return -1
        output_length = 1
    }
    if output == nil || output_capacity < output_length do return -2
    if operation == 0 {
        output[0] = u8(padding_count)
        for index := c.size_t(0); index < data_length; index += 1 {
            value := input[4 + index]
            if index >= offset && index < offset + padding_count { value = i64(padding_count) }
            output[index + 1] = u8(value)
        }
    } else if operation == 1 {
        for index := c.size_t(0); index < output_length; index += 1 {
            output[index] = u8(input[4 + index])
        }
    } else {
        output[0] = u8(padding_count)
    }
    return i64(output_length)
}
