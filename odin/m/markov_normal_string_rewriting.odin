package markov_normal_string_rewriting

import "core:c"

MAX_RULES :: 8
MAX_STEPS :: 32
MAX_WORD :: 64
MAX_INPUT :: 204

@(export)
markov_normal_string_rewriting :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > MAX_RULES || input[1] < 0 || input[1] > MAX_STEPS || input[2] < 0 || input[2] > 48 do return -1
    count := int(input[0])
    budget := int(input[1])
    word_len := int(input[2])
    if int(length) < 3 + word_len do return -1
    var word: [MAX_WORD]i64
    cursor := 3
    for i := 0; i < word_len; i += 1 {
        if input[cursor] < 0 || input[cursor] > 25 do return -1
        word[i] = input[cursor]
        cursor += 1
    }
    var kinds: [MAX_RULES]i64
    var lhs_len: [MAX_RULES]int
    var rhs_len: [MAX_RULES]int
    var lhs: [MAX_RULES * 8]i64
    var rhs: [MAX_RULES * 8]i64
    for r := 0; r < count; r += 1 {
        if cursor + 3 > int(length) do return -1
        kind := input[cursor]
        left := input[cursor + 1]
        right := input[cursor + 2]
        cursor += 3
        if (kind != 0 && kind != 1) || left < 1 || left > 8 || right < 0 || right > 8 do return -1
        lhs_len[r] = int(left)
        rhs_len[r] = int(right)
        kinds[r] = kind
        if cursor + lhs_len[r] + rhs_len[r] > int(length) do return -1
        for j := 0; j < lhs_len[r]; j += 1 {
            if input[cursor] < 0 || input[cursor] > 25 do return -1
            lhs[r * 8 + j] = input[cursor]
            cursor += 1
        }
        for j := 0; j < rhs_len[r]; j += 1 {
            if input[cursor] < 0 || input[cursor] > 25 do return -1
            rhs[r * 8 + j] = input[cursor]
            cursor += 1
        }
    }
    if cursor != int(length) do return -1

    rewrites := 0
    halt: u8 = 0
    for {
        chosen := count
        offset := 0
        for r := 0; r < count && chosen == count; r += 1 {
            if lhs_len[r] > word_len do continue
            for at := 0; at <= word_len - lhs_len[r]; at += 1 {
                same := true
                for j := 0; j < lhs_len[r]; j += 1 {
                    if word[at + j] != lhs[r * 8 + j] { same = false; break }
                }
                if same { chosen = r; offset = at; break }
            }
        }
        if chosen == count { halt = 0; break }
        if rewrites == budget { halt = 2; break }
        next_len := word_len - lhs_len[chosen] + rhs_len[chosen]
        if next_len > MAX_WORD do return -3
        var next: [MAX_WORD]i64
        out := 0
        for i := 0; i < offset; i += 1 { next[out] = word[i]; out += 1 }
        for i := 0; i < rhs_len[chosen]; i += 1 { next[out] = rhs[chosen * 8 + i]; out += 1 }
        for i := offset + lhs_len[chosen]; i < word_len; i += 1 { next[out] = word[i]; out += 1 }
        word = next
        word_len = next_len
        rewrites += 1
        if kinds[chosen] == 1 { halt = 1; break }
    }
    required := 3 + word_len
    if output == nil || int(capacity) < required do return -2
    output[0] = halt
    output[1] = u8(rewrites)
    output[2] = u8(word_len)
    for i := 0; i < word_len; i += 1 { output[3 + i] = u8(word[i]) }
    return i64(required)
}
