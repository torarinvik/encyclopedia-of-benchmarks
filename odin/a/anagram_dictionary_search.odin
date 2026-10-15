package anagram_dictionary_search

import "core:c"

MAX_WORDS :: 16
MAX_WORD_LENGTH :: 16

is_anagram :: proc "contextless" (input: [^]i64, query_length, word_offset, word_length: int) -> bool {
    if query_length != word_length do return false
    counts: [26]int
    for i := 0; i < query_length; i += 1 {
        counts[int(input[2+i])-97] += 1
        counts[int(input[word_offset+i])-97] -= 1
    }
    for count in counts do if count != 0 do return false
    return true
}

put_byte :: proc(output: [^]u8, capacity: c.size_t, length: ^c.size_t, value: u8) -> bool {
    if length^ >= capacity do return false
    output[length^] = value
    length^ += 1
    return true
}

@(export)
anagram_dictionary_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_WORDS || input[1] < 0 || input[1] > MAX_WORD_LENGTH do return -1
    word_count, query_length := int(input[0]), int(input[1])
    if 2 + query_length > int(length) do return -1
    for i := 0; i < query_length; i += 1 do if input[2+i] < 97 || input[2+i] > 122 do return -1
    if output == nil do return -2
    offset := 2 + query_length
    output_length := c.size_t(0)
    for item := 0; item < word_count; item += 1 {
        if offset >= int(length) || input[offset] < 1 || input[offset] > MAX_WORD_LENGTH do return -1
        word_length := int(input[offset]); offset += 1
        if offset + word_length > int(length) do return -1
        for i := 0; i < word_length; i += 1 do if input[offset+i] < 97 || input[offset+i] > 122 do return -1
        if is_anagram(input, query_length, offset, word_length) {
            for i := 0; i < word_length; i += 1 {
                if !put_byte(output, capacity, &output_length, u8(input[offset+i])) do return -2
            }
            if !put_byte(output, capacity, &output_length, u8('\n')) do return -2
        }
        offset += word_length
    }
    if offset != int(length) do return -1
    if !put_byte(output, capacity, &output_length, 0) do return -2
    return i64(output_length)
}
