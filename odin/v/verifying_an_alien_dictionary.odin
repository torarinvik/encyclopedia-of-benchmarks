package verifying_an_alien_dictionary

import "core:c"

@(export)
verifying_an_alien_dictionary :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 27 || length > 2127 || input[0] < 1 || input[0] > 100 do return -1
    word_count := int(input[0])
    rank: [26]i64 = {}
    order_seen: [26]bool = {}
    for position := 0; position < 26; position += 1 {
        letter := input[1 + position]
        if letter < i64('a') || letter > i64('z') do return -1
        index := int(letter - i64('a'))
        if order_seen[index] do return -1
        order_seen[index] = true
        rank[index] = i64(position)
    }

    starts: [100]int = {}
    word_lengths: [100]int = {}
    offset := 27
    for word := 0; word < word_count; word += 1 {
        if offset >= int(length) || input[offset] < 1 || input[offset] > 20 do return -1
        word_length := int(input[offset])
        offset += 1
        if word_length > int(length) - offset do return -1
        starts[word] = offset
        word_lengths[word] = word_length
        for character := 0; character < word_length; character += 1 {
            letter := input[offset + character]
            if letter < i64('a') || letter > i64('z') do return -1
        }
        offset += word_length
    }
    if offset != int(length) do return -1

    for word := 0; word + 1 < word_count; word += 1 {
        left_length := word_lengths[word]
        right_length := word_lengths[word + 1]
        limit := left_length
        if right_length < limit do limit = right_length
        decided := false
        for character := 0; character < limit; character += 1 {
            left_letter := int(input[starts[word] + character] - i64('a'))
            right_letter := int(input[starts[word + 1] + character] - i64('a'))
            if rank[left_letter] < rank[right_letter] {
                decided = true
                break
            }
            if rank[left_letter] > rank[right_letter] do return 0
        }
        if !decided && left_length > right_length do return 0
    }
    return 1
}
