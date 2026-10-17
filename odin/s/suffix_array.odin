package suffix_array

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: 65

pair_less :: proc "contextless" (left, right: int, rank: [^]i64, length, step: int) -> bool {
    if rank[left] != rank[right] do return rank[left] < rank[right]
    left_second: i64 = -1
    right_second: i64 = -1
    if left + step < length { left_second = rank[left + step] }
    if right + step < length { right_second = rank[right + step] }
    return left_second < right_second
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: int) {
    bits := u64(value)
    for byte: int = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(byte * 8))
    }
}

@(export)
suffix_array :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    count_value := values[0]
    if count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
    count := int(count_value)
    if length != c.size_t(1 + count) do return -1
    for i in 0..<count {
        if values[1 + i] < 0 || values[1 + i] > 127 do return -1
    }

    output_bytes := count * 8
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    if count == 0 do return 0

    suffixes: [MAX_TEXT_LENGTH]int = {}
    rank: [MAX_TEXT_LENGTH]i64 = {}
    next_rank: [MAX_TEXT_LENGTH]i64 = {}
    for i in 0..<count {
        suffixes[i] = i
        rank[i] = values[1 + i]
    }

    step := 1
    for step < count {
        for i := 1; i < count; i += 1 {
            key := suffixes[i]
            position := i
            for position > 0 && pair_less(key, suffixes[position - 1], raw_data(rank[:]), count, step) {
                suffixes[position] = suffixes[position - 1]
                position -= 1
            }
            suffixes[position] = key
        }
        next_rank[suffixes[0]] = 0
        for i := 1; i < count; i += 1 {
            previous := suffixes[i - 1]
            current := suffixes[i]
            previous_second: i64 = -1
            current_second: i64 = -1
            if previous + step < count { previous_second = rank[previous + step] }
            if current + step < count { current_second = rank[current + step] }
            next_rank[current] = next_rank[previous]
            if rank[previous] != rank[current] || previous_second != current_second {
                next_rank[current] += 1
            }
        }
        for i in 0..<count { rank[i] = next_rank[i] }
        if rank[suffixes[count - 1]] == i64(count - 1) do break
        step *= 2
    }

    for i in 0..<count { put_i64_le(output, i * 8, suffixes[i]) }
    return i64(output_bytes)
}
