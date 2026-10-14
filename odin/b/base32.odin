package base32

import "core:c"

base32_value :: proc "contextless" (byte: i64) -> i64 {
    if byte >= i64('A') && byte <= i64('Z') do return byte - i64('A')
    if byte >= i64('2') && byte <= i64('7') do return byte - i64('2') + 26
    return -1
}

@(export)
base32 :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 1 || length > 66 do return -1
    mode := input[0]
    if mode == 0 {
        count := length - 1
        for index := c.size_t(1); index < length; index += 1 {
            if input[index] < 0 || input[index] > 255 do return -1
        }
        output_length := c.size_t(0)
        if count > 0 do output_length = ((count + 4) / 5) * 8
        if output_capacity < output_length do return -2
        written := c.size_t(0)
        alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        for start := c.size_t(0); start < count; start += 5 {
            bytes := count - start
            if bytes > 5 do bytes = 5
            bits := bytes * 8
            symbols := (bits + 4) / 5
            for symbol := c.size_t(0); symbol < 8; symbol += 1 {
                if symbol >= symbols {
                    output[written] = u8('=')
                } else {
                    value := u8(0)
                    for bit := symbol * 5; bit < symbol * 5 + 5; bit += 1 {
                        value = value << 1
                        if bit < bits {
                            byte := u8(input[1 + start + bit / 8])
                            value |= (byte >> u8(7 - bit % 8)) & 1
                        }
                    }
                    output[written] = alphabet[value]
                }
                written += 1
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
        if base32_value(input[index + 1]) < 0 do return -1
    }
    for index := content_length; index < encoded_length; index += 1 {
        if input[index + 1] != i64('=') do return -1
    }
    remainder := content_length % 8
    expected_padding := c.size_t(0)
    if remainder == 2 { expected_padding = 6 }
    else if remainder == 4 { expected_padding = 4 }
    else if remainder == 5 { expected_padding = 3 }
    else if remainder == 7 { expected_padding = 1 }
    else if remainder != 0 { return -1 }
    if padding != 0 && (encoded_length % 8 != 0 || padding != expected_padding) do return -1
    if content_length > 0 && remainder != 0 {
        final_value := c.size_t(base32_value(input[content_length]))
        unused := c.size_t(3)
        if remainder == 2 { unused = 2 }
        else if remainder == 4 { unused = 4 }
        else if remainder == 5 { unused = 1 }
        else if remainder == 7 { unused = 3 }
        if final_value % (1 << unused) != 0 do return -1
    }
    output_length := content_length * 5 / 8
    if output_capacity < output_length do return -2
    for index := c.size_t(0); index < output_length; index += 1 {
        byte := u8(0)
        for bit := index * 8; bit < index * 8 + 8; bit += 1 {
            symbol := c.size_t(base32_value(input[1 + bit / 5]))
            byte = (byte << 1) | u8((symbol / (1 << (4 - bit % 5))) % 2)
        }
        output[index] = byte
    }
    return i64(output_length)
}
