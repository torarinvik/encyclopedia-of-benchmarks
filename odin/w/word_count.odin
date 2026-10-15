package word_count

import "core:c"

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
word_count :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 1050 || values[0] < 0 || values[0] > 999 do return -1
    text_length := int(values[0])
    query_index := 1 + text_length
    if query_index >= int(length) || values[query_index] < 0 || values[query_index] > 49 do return -1
    query_length := int(values[query_index])
    if int(length) != query_index + 1 + query_length do return -1
    for index := 1; index < query_index; index += 1 {
        if values[index] < 1 || values[index] > 127 do return -1
    }
    for index := query_index + 1; index < int(length); index += 1 {
        if values[index] < 1 || values[index] > 127 do return -1
    }
    total, matches, start := 0, 0, 0
    for finish := 0; finish <= text_length; finish += 1 {
        if finish == text_length || values[1 + finish] == 32 {
            token_length := finish - start
            if token_length > 49 do return -1
            if total >= 20 do return -2
            if token_length == query_length {
                offset := 0
                for offset < token_length && values[1 + start + offset] == values[query_index + 1 + offset] {
                    offset += 1
                }
                if offset == token_length do matches += 1
            }
            total += 1
            start = finish + 1
        }
    }
    if output == nil || output_capacity < 16 do return -2
    store_i64_le(output, 0, i64(total)); store_i64_le(output, 8, i64(matches))
    return 16
}
