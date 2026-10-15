module word_count

fn store_i64_le(mut output &u8, offset int, value i64) {
    mut bits := u64(value)
    for byte in 0 .. 8 {
        unsafe { output[offset + byte] = u8(bits & 255) }
        bits >>= 8
    }
}

// Count literal-space-delimited words and requested-word matches.
@[export: 'word_count']
pub fn word_count(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 2 || length > 1050 || values[0] < 0 || values[0] > 999 { return -1 }
    text_length := int(values[0])
    query_index := 1 + text_length
    if query_index >= int(length) || values[query_index] < 0 || values[query_index] > 49 { return -1 }
    query_length := int(values[query_index])
    if int(length) != query_index + 1 + query_length { return -1 }
    for index in 1 .. query_index {
        if values[index] < 1 || values[index] > 127 { return -1 }
    }
    for index in query_index + 1 .. int(length) {
        if values[index] < 1 || values[index] > 127 { return -1 }
    }
    mut total := 0
    mut matches := 0
    mut start := 0
    for finish in 0 .. (text_length + 1) {
        if finish == text_length || values[1 + finish] == 32 {
            token_length := finish - start
            if token_length > 49 { return -1 }
            if total >= 20 { return -2 }
            if token_length == query_length {
                mut offset := 0
                for offset < token_length && values[1 + start + offset] == values[query_index + 1 + offset] { offset++ }
                if offset == token_length { matches++ }
            }
            total++
            start = finish + 1
        }
    }
    if output_capacity < 16 { return -2 }
    store_i64_le(mut output, 0, i64(total)); store_i64_le(mut output, 8, i64(matches))
    return 16
}
