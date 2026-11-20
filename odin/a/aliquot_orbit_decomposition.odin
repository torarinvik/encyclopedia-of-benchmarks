package aliquot_orbit_decomposition

import "core:c"

MAX_TERMS :: 4097
MAX_INPUT :: 3
MAX_SEED :: i64(100000)
MAX_VALUE :: i64(100000)
MAX_TRANSITIONS :: i64(4096)

aliquot_sum :: proc "contextless" (value: i64) -> i64 {
    if value == 1 do return 0
    total := i64(1)
    for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 {
            total += divisor
            partner := value / divisor
            if partner != divisor do total += partner
        }
    }
    return total
}

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
aliquot_orbit_decomposition :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT) do return -1
    if length != 2 || input[0] < 1 || input[0] > MAX_SEED ||
        input[1] < 1 || input[1] > MAX_TRANSITIONS do return -1

    keys: [MAX_TERMS]i64
    first_indices: [MAX_TERMS]i64
    key_count := 0
    words: [3]i64
    current := input[0]
    transitions := i64(0)
    positive_count := i64(0)
    for {
        if current == 0 {
            words[0] = 0
            words[1] = positive_count
            words[2] = 0
            break
        }
        low := 0
        high := key_count
        for low < high {
            middle := low + (high - low) / 2
            if keys[middle] < current do low = middle + 1 else high = middle
        }
        if low < key_count && keys[low] == current {
            words[0] = 1
            words[1] = first_indices[low]
            words[2] = transitions - first_indices[low]
            break
        }
        cursor := key_count
        for cursor > low {
            keys[cursor] = keys[cursor - 1]
            first_indices[cursor] = first_indices[cursor - 1]
            cursor -= 1
        }
        keys[low] = current
        first_indices[low] = transitions
        key_count += 1
        positive_count += 1
        if transitions >= input[1] {
            words[0] = -3
            words[1] = transitions
            words[2] = current
            break
        }
        next_value := aliquot_sum(current)
        transitions += 1
        if next_value > MAX_VALUE {
            words[0] = -2
            words[1] = transitions
            words[2] = next_value
            break
        }
        current = next_value
    }

    if output == nil || capacity < 24 do return -2
    for word := 0; word < 3; word += 1 do store_i64(output, word * 8, words[word])
    return 24
}
