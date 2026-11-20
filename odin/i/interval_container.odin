package interval_container

import "core:c"

MAX_OPERATIONS :: 24
RECORD_WIDTH :: 3
MAX_INPUT_VALUES :: c.size_t(73)
MAX_INTERVALS :: 25
DOMAIN_END :: i64(32)

Interval :: struct { left, right: i64 }

add_interval :: proc "contextless" (items: ^[MAX_INTERVALS]Interval, count: ^int,
    left_in, right_in: i64) {
    if left_in == right_in do return
    left, right := left_in, right_in
    next: [MAX_INTERVALS]Interval
    out := 0
    inserted := false
    for i in 0..<count^ {
        current := items[i]
        if current.right < left {
            next[out] = current
            out += 1
        } else if right < current.left {
            if !inserted {
                next[out] = {left, right}
                out += 1
                inserted = true
            }
            next[out] = current
            out += 1
        } else {
            left = min(left, current.left)
            right = max(right, current.right)
        }
    }
    if !inserted {
        next[out] = {left, right}
        out += 1
    }
    for i in 0..<out do items[i] = next[i]
    count^ = out
}

remove_interval :: proc "contextless" (items: ^[MAX_INTERVALS]Interval, count: ^int,
    left, right: i64) {
    if left == right do return
    next: [MAX_INTERVALS + 1]Interval
    out := 0
    for i in 0..<count^ {
        current := items[i]
        if current.right <= left || current.left >= right {
            next[out] = current
            out += 1
        } else {
            if current.left < left {
                next[out] = {current.left, left}
                out += 1
            }
            if current.right > right {
                next[out] = {right, current.right}
                out += 1
            }
        }
    }
    for i in 0..<out do items[i] = next[i]
    count^ = out
}

covered_length :: proc "contextless" (items: ^[MAX_INTERVALS]Interval, count: int) -> i64 {
    total: i64 = 0
    for i in 0..<count do total += items[i].right - items[i].left
    return total
}

valid_input :: proc "contextless" (input: [^]i64, length: c.size_t,
    operation_count: ^int) -> bool {
    if input == nil || length < 1 || length > MAX_INPUT_VALUES do return false
    if input[0] < 0 || input[0] > MAX_OPERATIONS do return false
    operation_count^ = int(input[0])
    if length != c.size_t(1 + operation_count^ * RECORD_WIDTH) do return false
    for i in 0..<operation_count^ {
        offset := 1 + i * RECORD_WIDTH
        opcode, left, right := input[offset], input[offset + 1], input[offset + 2]
        if opcode < 0 || opcode > 1 || left < 0 || right < left || right > DOMAIN_END do
            return false
    }
    return true
}

@(export)
interval_container :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    operation_count: int
    if !valid_input(input, length, &operation_count) do return -1
    items: [MAX_INTERVALS]Interval
    count := 0
    checksum: i64 = 0
    for i in 0..<operation_count {
        offset := 1 + i * RECORD_WIDTH
        opcode, left, right := input[offset], input[offset + 1], input[offset + 2]
        if opcode == 0 do add_interval(&items, &count, left, right)
        else do remove_interval(&items, &count, left, right)
        checksum += i64(i + 1) * covered_length(&items, count)
    }
    return checksum
}
