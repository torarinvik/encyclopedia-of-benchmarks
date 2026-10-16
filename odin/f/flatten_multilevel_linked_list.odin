package flatten_multilevel_linked_list

import "core:c"

MAX_LISTS :: 8
MAX_CHAIN_LENGTH :: 8
MAX_TOTAL_VALUES :: MAX_LISTS * MAX_CHAIN_LENGTH
MAX_INPUT_LENGTH :: 1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH)

merge_recursive :: proc "c" (left: [^]i64, left_length, left_index: int,
        right: [^]i64, right_length, right_index: int,
        output: [^]i64, output_index: int) -> int {
    if left_index == left_length {
        remaining := right_length - right_index
        for i := 0; i < remaining; i += 1 { output[output_index + i] = right[right_index + i] }
        return output_index + remaining
    }
    if right_index == right_length {
        remaining := left_length - left_index
        for i := 0; i < remaining; i += 1 { output[output_index + i] = left[left_index + i] }
        return output_index + remaining
    }
    if left[left_index] < right[right_index] {
        output[output_index] = left[left_index]
        return merge_recursive(left, left_length, left_index + 1, right, right_length,
            right_index, output, output_index + 1)
    }
    output[output_index] = right[right_index]
    return merge_recursive(left, left_length, left_index, right, right_length,
        right_index + 1, output, output_index + 1)
}

flatten_suffix :: proc "c" (lists: [^]i64, lengths: [^]int,
        count, index: int, output: [^]i64) -> int {
    row := index * MAX_CHAIN_LENGTH
    if index + 1 == count {
        for i := 0; i < lengths[index]; i += 1 { output[i] = lists[row + i] }
        return lengths[index]
    }
    suffix: [MAX_TOTAL_VALUES]i64
    suffix_length := flatten_suffix(lists, lengths, count, index + 1, &suffix[0])
    return merge_recursive(&lists[row], lengths[index], 0, &suffix[0], suffix_length, 0, output, 0)
}

store_i64 :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
    }
}

@(export)
flatten_multilevel_linked_list :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if values[0] < 0 || values[0] > MAX_LISTS do return -1
    count := int(values[0])
    if count == 0 { return if length == 1 do 0 else -1 }

    lists: [MAX_LISTS * MAX_CHAIN_LENGTH]i64
    lengths: [MAX_LISTS]int
    total := 0
    cursor := 1
    input_length := int(length)
    for list := 0; list < count; list += 1 {
        if cursor >= input_length || values[cursor] < 1 || values[cursor] > MAX_CHAIN_LENGTH do return -1
        chain_length := int(values[cursor])
        cursor += 1
        if chain_length > input_length - cursor do return -1
        lengths[list] = chain_length
        row := list * MAX_CHAIN_LENGTH
        for item := 0; item < chain_length; item += 1 {
            value := values[cursor]
            cursor += 1
            if value < -1000 || value > 1000 ||
                (item > 0 && value < lists[row + item - 1]) { return -1 }
            lists[row + item] = value
        }
        total += chain_length
    }
    if cursor != input_length do return -1
    required := total * 8
    if output == nil || capacity < c.size_t(required) do return -2

    flattened: [MAX_TOTAL_VALUES]i64
    _ = flatten_suffix(&lists[0], &lengths[0], count, 0, &flattened[0])
    for i := 0; i < total; i += 1 { store_i64(output, 8 * i, flattened[i]) }
    return i64(total)
}
