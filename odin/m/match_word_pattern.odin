package match_word_pattern

import "core:c"

MAX_PATTERN_LENGTH :: 8
MAX_TEXT_LENGTH :: 32
MAX_INPUT_LENGTH :: 43

match_word_pattern_search :: proc "contextless" (
    input: [^]i64, pattern_length, text_start, text_length: int,
    pattern_index, text_index: int, mapped_start, mapped_length: [^]int,
) -> bool {
    if pattern_index == pattern_length do return text_index == text_length
    if text_index == text_length do return false

    symbol := int(input[2 + pattern_index])
    known_length := mapped_length[symbol]
    if known_length != 0 {
        if known_length > text_length - text_index do return false
        for offset := 0; offset < known_length; offset += 1 {
            if input[text_start + mapped_start[symbol] + offset] != input[text_start + text_index + offset] do return false
        }
        return match_word_pattern_search(
            input, pattern_length, text_start, text_length,
            pattern_index + 1, text_index + known_length, mapped_start, mapped_length,
        )
    }

    for ending := text_index + 1; ending <= text_length; ending += 1 {
        candidate_length := ending - text_index
        already_used := false
        for other_index := 0; other_index < pattern_index; other_index += 1 {
            other := int(input[2 + other_index])
            if other == symbol do continue
            if mapped_length[other] == candidate_length {
                equal := true
                for offset := 0; offset < candidate_length; offset += 1 {
                    if input[text_start + mapped_start[other] + offset] != input[text_start + text_index + offset] {
                        equal = false
                        break
                    }
                }
                if equal {
                    already_used = true
                    break
                }
            }
        }
        if already_used do continue

        mapped_start[symbol] = text_index
        mapped_length[symbol] = candidate_length
        if match_word_pattern_search(
            input, pattern_length, text_start, text_length,
            pattern_index + 1, ending, mapped_start, mapped_length,
        ) {
            return true
        }
        mapped_length[symbol] = 0
    }
    return false
}

@(export)
match_word_pattern :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH do return -1
    if input[0] < 0 || input[0] > MAX_PATTERN_LENGTH
        || input[1] < 0 || input[1] > MAX_TEXT_LENGTH do return -1
    pattern_length := int(input[0])
    text_length := int(input[1])
    if int(input_length) != 2 + pattern_length + text_length do return -1
    for index := 0; index < pattern_length + text_length; index += 1 {
        if input[2 + index] < 0 || input[2 + index] > 127 do return -1
    }

    mapped_start: [128]int
    mapped_length: [128]int
    if match_word_pattern_search(
        input, pattern_length, 2 + pattern_length, text_length,
        0, 0, &mapped_start[0], &mapped_length[0],
    ) {
        return 1
    }
    return 0
}
