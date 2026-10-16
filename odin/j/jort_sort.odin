package jort_sort

import "core:c"

MAX_LENGTH :: 64

@(export)
jort_sort :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 do return 1
    if values == nil || length > MAX_LENGTH do return -1
    copy: [MAX_LENGTH]i64
    for i in 0 .. int(length) { copy[i] = values[i] }
    for i in 2 .. int(length) {
        key := copy[i]
        position := i
        for position > 1 && copy[position - 1] > key {
            copy[position] = copy[position - 1]
            position -= 1
        }
        copy[position] = key
    }
    for i in 0 .. int(length) { if copy[i] != values[i] do return 0 }
    return 1
}
