package flash_sort

import "core:c"

MAX_LENGTH :: 64

valid_length :: proc(length: int) -> bool { return length <= 1 || (length >= 3 && length <= MAX_LENGTH) }
class_of :: proc(value, minimum, range: i64, classes: int) -> int {
    return int((i64(classes - 1) * (value - minimum)) / range)
}

flash_sort_values :: proc(values: []i64, length: int) -> bool {
    if length <= 1 do return true
    minimum, maximum := values[0], values[0]
    for index in 1..<length {
        if values[index] < minimum do minimum = values[index]
        if values[index] > maximum do maximum = values[index]
    }
    if minimum == maximum do return true
    range := maximum - minimum
    classes := (9 * length) / 20
    if classes < 1 do classes = 1
    class_ends: [MAX_LENGTH]int
    for index in 0..<length { class_ends[class_of(values[index], minimum, range, classes)] += 1 }
    for index in 1..<classes { class_ends[index] += class_ends[index - 1] }
    moves, j, k := 0, 0, classes - 1
    for moves < length - 1 {
        for j > class_ends[k] - 1 {
            j += 1
            if j >= length do return false
            k = class_of(values[j], minimum, range, classes)
        }
        flash := values[j]
        for j != class_ends[k] {
            k = class_of(flash, minimum, range, classes)
            class_ends[k] -= 1
            target := class_ends[k]
            hold := values[target]
            values[target] = flash
            flash = hold
            moves += 1
        }
    }
    for index in 1..<length {
        key := values[index]
        cursor := index
        for cursor > 0 && values[cursor - 1] > key {
            values[cursor] = values[cursor - 1]
            cursor -= 1
        }
        values[cursor] = key
    }
    return true
}

@(export)
flash_sort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > c.size_t(65) do return -1
    n := int(length)
    if !valid_length(n) || (n != 0 && input == nil) do return -1
    values: [MAX_LENGTH]i64
    for index in 0..<n {
        if input[index] < -1_000_000 || input[index] > 1_000_000 do return -1
        values[index] = input[index]
    }
    output_bytes := n * 4
    if output_capacity < c.size_t(output_bytes) || (output_bytes != 0 && output == nil) do return -2
    if !flash_sort_values(values[:], n) do return -1
    for index in 0..<n {
        bits := u32(i32(values[index]))
        for byte in 0..<4 { output[index * 4 + byte] = u8((bits >> (8 * byte)) & 255) }
    }
    return i64(output_bytes)
}
