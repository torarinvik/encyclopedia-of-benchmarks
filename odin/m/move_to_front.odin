package move_to_front

import "core:c"

@(export)
move_to_front :: proc "c" (values: [^]i64, length: c.size_t,
                              output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 164 do return -1
    mode, alphabet_length, text_length := values[0], values[1], values[2]
    if (mode != 0 && mode != 1) || alphabet_length < 0 || alphabet_length > 32 ||
       text_length < 0 || text_length > 128 || length != 3 + c.size_t(alphabet_length + text_length) do return -1
    alphabet: [32]i64 = {}
    result: [128]u8 = {}
    for i in 0 ..< int(alphabet_length) {
        symbol := values[3 + i]
        if symbol < 0 || symbol > 127 do return -1
        for j in 0 ..< i { if alphabet[j] == symbol do return -1 }
        alphabet[i] = symbol
    }
    result_length := 0
    if mode == 0 {
        if text_length > 0 && alphabet_length == 0 do return -1
        for i in 0 ..< int(text_length) {
            symbol := values[3 + int(alphabet_length) + i]
            if symbol < 0 || symbol > 127 do return -1
            position := 0
            for position < int(alphabet_length) && alphabet[position] != symbol { position += 1 }
            if position == int(alphabet_length) do return -1
            result[result_length] = u8(position)
            result_length += 1
            for position > 0 { alphabet[position] = alphabet[position - 1]; position -= 1 }
            alphabet[0] = symbol
        }
    } else if alphabet_length > 0 {
        for i in 0 ..< int(text_length) {
            index := values[3 + int(alphabet_length) + i]
            if index < 0 || index >= alphabet_length do return -1
            symbol := alphabet[int(index)]
            result[result_length] = u8(symbol)
            result_length += 1
            position := int(index)
            for position > 0 { alphabet[position] = alphabet[position - 1]; position -= 1 }
            alphabet[0] = symbol
        }
    }
    if capacity < c.size_t(result_length) || (result_length > 0 && output == nil) do return -2
    for i in 0 ..< result_length { output[i] = result[i] }
    return i64(result_length)
}
