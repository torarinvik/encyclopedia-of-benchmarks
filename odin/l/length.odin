package length

import "core:c"

MAX_PAYLOAD_BYTES :: 256
MAX_INPUT_LENGTH :: 259
OUTPUT_BYTES :: 16

utf8_scalar_count :: proc "contextless" (bytes: [^]u8, payload_length: int) -> i64 {
    index := 0
    count := i64(0)
    for index < payload_length {
        lead := bytes[index]
        if lead >= 1 && lead <= 0x7f {
            index += 1
        } else if lead >= 0xc2 && lead <= 0xdf {
            if index + 1 >= payload_length || bytes[index + 1] < 0x80 || bytes[index + 1] > 0xbf do return -1
            index += 2
        } else if lead >= 0xe0 && lead <= 0xef {
            if index + 2 >= payload_length do return -1
            second, third := bytes[index + 1], bytes[index + 2]
            if second < 0x80 || second > 0xbf || third < 0x80 || third > 0xbf ||
                (lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f) do return -1
            index += 3
        } else do return -1
        count += 1
    }
    return count
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
length :: proc "c" (input: [^]i64, input_length: c.size_t,
                    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
    if input[0] < 0 || input[0] > MAX_PAYLOAD_BYTES do return -1
    payload_length := int(input[0])
    if int(input_length) != payload_length + 2 do return -1

    payload: [MAX_PAYLOAD_BYTES]u8
    for index := 0; index <= payload_length; index += 1 {
        value := input[index + 1]
        if value < 0 || value > 255 do return -1
        if index == payload_length {
            if value != 0 do return -1
        } else {
            if value == 0 do return -1
            payload[index] = u8(value)
        }
    }
    scalar_count := utf8_scalar_count(&payload[0], payload_length)
    if scalar_count < 0 do return -1
    if output == nil || output_capacity < OUTPUT_BYTES do return -2

    put_i64_le(output, 0, i64(payload_length))
    put_i64_le(output, 8, scalar_count)
    return OUTPUT_BYTES
}
