package permutation_sort

import "core:c"

MAX_LENGTH :: 8
INVALID_RESULT :: i64(-1)

permutation_sort_is_sorted :: proc(values: [MAX_LENGTH]i64, length: int) -> bool {
    for index := 1; index < length; index += 1 {
        if values[index - 1] > values[index] { return false }
    }
    return true
}

@(export)
permutation_sort :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > c.size_t(MAX_LENGTH) { return INVALID_RESULT }

    working: [MAX_LENGTH]i64 = {}
    counters: [MAX_LENGTH]int = {}
    input_length := int(length)
    for index := 0; index < input_length; index += 1 { working[index] = values[index] }

    checked := i64(1)
    if permutation_sort_is_sorted(working, input_length) { return checked }

    index := 0
    for index < input_length {
        if counters[index] < index {
            swap_index := 0
            if index % 2 != 0 { swap_index = counters[index] }
            temporary := working[swap_index]
            working[swap_index] = working[index]
            working[index] = temporary
            counters[index] += 1
            checked += 1
            if permutation_sort_is_sorted(working, input_length) { return checked }
            index = 0
        } else {
            counters[index] = 0
            index += 1
        }
    }
    return INVALID_RESULT
}
