package base64

import "core:c"

base64_value :: proc "contextless" (byte: i64) -> i64 {
    if byte >= i64('A') && byte <= i64('Z') do return byte - i64('A')
    if byte >= i64('a') && byte <= i64('z') do return byte - i64('a') + 26
    if byte >= i64('0') && byte <= i64('9') do return byte - i64('0') + 52
    if byte == i64('+') do return 62
    if byte == i64('/') do return 63
    return -1
}

@(export)
base64 :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 1 || length > 66 do return -1
    mode := input[0]
    if mode == 0 {
        count := length - 1
        for index := c.size_t(1); index < length; index += 1 {
            if input[index] < 0 || input[index] > 255 do return -1
        }
        output_length := c.size_t(0)
        if count > 0 do output_length = ((count + 2) / 3) * 4
        symbols := (count * 8 + 5) / 6
        if output_capacity < output_length do return -2
        alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        for index := c.size_t(0); index < output_length; index += 1 {
            if index >= symbols {
                output[index] = u8('=')
            } else {
                value := u8(0)
                for bit := index * 6; bit < index * 6 + 6; bit += 1 {
                    value = value << 1
                    if bit < count * 8 {
                        byte := u8(input[1 + bit / 8])
                        value |= (byte >> u8(7 - bit % 8)) & 1
                    }
                }
                output[index] = alphabet[value]
            }
        }
        return i64(output_length)
    }
    if mode != 1 do return -1
    encoded_length := length - 1
    content_length := encoded_length
    for index := c.size_t(0); index < encoded_length; index += 1 {
        if input[index + 1] == i64('=') { content_length = index; break }
    }
    padding := encoded_length - content_length
    for index := c.size_t(0); index < content_length; index += 1 {
        if base64_value(input[index + 1]) < 0 do return -1
    }
    for index := content_length; index < encoded_length; index += 1 {
        if input[index + 1] != i64('=') do return -1
    }
    remainder := content_length % 4
    expected_padding := c.size_t(0)
    if remainder == 2 { expected_padding = 2 }
    else if remainder == 3 { expected_padding = 1 }
    else if remainder != 0 { return -1 }
    if padding != 0 && (encoded_length % 4 != 0 || padding != expected_padding) do return -1
    if content_length > 0 && remainder != 0 {
        final_value := c.size_t(base64_value(input[content_length]))
        unused := c.size_t(2)
        if remainder == 2 do unused = 4
        if final_value % (1 << unused) != 0 do return -1
    }
    output_length := content_length * 6 / 8
    if output_capacity < output_length do return -2
    for index := c.size_t(0); index < output_length; index += 1 {
        byte := u8(0)
        for bit := index * 8; bit < index * 8 + 8; bit += 1 {
            symbol := c.size_t(base64_value(input[1 + bit / 6]))
            byte = (byte << 1) | u8((symbol / (1 << (5 - bit % 6))) % 2)
        }
        output[index] = byte
    }
    return i64(output_length)
}
