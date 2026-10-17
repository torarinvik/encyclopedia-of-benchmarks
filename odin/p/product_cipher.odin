package product_cipher

import "core:c"

MAX_TEXT_LENGTH :: 256
MAX_COLUMNS :: 64
MAX_INPUT_VALUES :: 259
MAX_OUTPUT_BYTES :: 315

@(export)
product_cipher :: proc "c" (input: [^]i64, length: c.size_t,
                             output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
    if input[0] < 1 || input[0] > MAX_COLUMNS ||
        input[1] < 0 || input[1] > MAX_TEXT_LENGTH do return -1

    columns := int(input[0])
    text_length := int(input[1])
    if int(length) != 2 + text_length do return -1
    for index := 0; index < text_length; index += 1 {
        byte := input[2 + index]
        if byte < 0 || byte > 127 || byte == 10 || byte == 13 do return -1
    }

    padded_length := 0
    if text_length > 0 do padded_length = ((text_length + columns - 1) / columns) * columns
    if padded_length > MAX_OUTPUT_BYTES do return -1
    if padded_length == 0 do return 0
    if output == nil || output_capacity < c.size_t(padded_length) do return -2

    padded: [MAX_OUTPUT_BYTES]u8
    for index := 0; index < text_length; index += 1 {
        padded[index] = u8(input[2 + index] + 5)
    }
    for index := text_length; index < padded_length; index += 1 {
        padded[index] = u8('/')
    }
    rows := padded_length / columns
    written := 0
    for column := 0; column < columns; column += 1 {
        for row := 0; row < rows; row += 1 {
            output[written] = padded[column + row * columns]
            written += 1
        }
    }
    return i64(written)
}
