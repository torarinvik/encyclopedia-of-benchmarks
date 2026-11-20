package ratcliff_obershelp_similarity

import "core:c"

MAX_TEXT :: 32
MAX_INPUT_LENGTH :: 67

longest_match :: proc(input: [^]i64, first_base, second_base: int,
                      a0, a1, b0, b1: int) -> i64 {
    var dp: [33]i64
    for index in 0..<33 { dp[index] = 0 }
    width := b1 - b0
    best_length := 0
    best_a := 0
    best_b := 0
    for i in a0..<a1 {
        diagonal := i64(0)
        for column in 1..<width+1 {
            old := dp[column]
            j := b0 + column - 1
            if input[first_base+i] == input[second_base+j] {
                current := int(diagonal) + 1
                dp[column] = i64(current)
                if current > best_length {
                    best_length = current
                    best_a = i + 1 - current
                    best_b = j + 1 - current
                }
            } else {
                dp[column] = 0
            }
            diagonal = old
        }
    }
    return i64(best_length*4096 + best_a*64 + best_b)
}

matched_characters :: proc(input: [^]i64, first_base, second_base: int,
                           a0, a1, b0, b1: int) -> i64 {
    if a0 >= a1 || b0 >= b1 do return 0
    packed := int(longest_match(input, first_base, second_base, a0, a1, b0, b1))
    block := packed / 4096
    if block == 0 do return 0
    rest := packed % 4096
    a := rest / 64
    b := rest % 64
    return i64(block) + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base, a+block, a1, b+block, b1)
}

@(export)
ratcliff_obershelp_similarity :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if input[0] < 0 || input[0] > i64(MAX_TEXT) || input[1] < 0 || input[1] > i64(MAX_TEXT) do return -1
    first_length := int(input[0])
    second_length := int(input[1])
    if length != c.size_t(2+first_length+second_length) do return -1
    for index in 0..<first_length+second_length {
        byte := input[2+index]
        if byte < 1 || byte > 127 do return -1
    }
    if first_length == 0 || second_length == 0 do return 0
    common := matched_characters(input, 2, 2+first_length,
                                 0, first_length, 0, second_length)
    return (200*common) / i64(first_length+second_length)
}
