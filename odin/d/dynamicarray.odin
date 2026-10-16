package dynamicarray

import "core:c"

write_word :: proc "contextless" (output: [^]u8, word: int, value: i64) {
    bits := cast(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[word * 8 + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
dynamicarray :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length < 1 || length > 385 || input[0] < 0 || input[0] > 128 do return -1
    a: [64]i64
    b: [64]i64
    queries: [128]i64
    size, capacity, cursor, query_count, active := 0, 0, 1, 0, 0
    for oi := 0; oi < int(input[0]); oi += 1 {
        if cursor >= int(length) do return -1
        op := input[cursor]
        cursor += 1
        if op == 0 {
            if cursor >= int(length) || size >= 64 do return -1
            if size == capacity {
                if active == 0 {
                    for i := 0; i < size; i += 1 { b[i] = a[i] }
                    active = 1
                } else {
                    for i := 0; i < size; i += 1 { a[i] = b[i] }
                    active = 0
                }
                if capacity == 0 { capacity = 10 } else { capacity *= 2 }
            }
            if active == 0 { a[size] = input[cursor] } else { b[size] = input[cursor] }
            size += 1
            cursor += 1
        } else if op == 1 {
            if cursor + 1 >= int(length) do return -1
            index, value := input[cursor], input[cursor + 1]
            cursor += 2
            if index < 0 || index >= i64(size) do return -1
            if active == 0 { a[int(index)] = value } else { b[int(index)] = value }
        } else if op == 2 || op == 3 {
            if cursor >= int(length) do return -1
            index := input[cursor]
            cursor += 1
            if index < 0 || index >= i64(size) do return -1
            at := int(index)
            if op == 2 {
                if query_count >= 128 do return -1
                if active == 0 { queries[query_count] = a[at] } else { queries[query_count] = b[at] }
                query_count += 1
            } else {
                if active == 0 { for i := at; i + 1 < size; i += 1 { a[i] = a[i + 1] } }
                else { for i := at; i + 1 < size; i += 1 { b[i] = b[i + 1] } }
                size -= 1
            }
        } else if op >= 4 && op <= 6 {
            if query_count >= 128 do return -1
            if op == 4 { queries[query_count] = i64(size) }
            else if op == 5 { queries[query_count] = i64(capacity) }
            else if size == 0 { queries[query_count] = 1 }
            else { queries[query_count] = 0 }
            query_count += 1
        } else { return -1 }
    }
    if cursor != int(length) do return -1
    words := 3 + query_count + size
    if output == nil || output_capacity < c.size_t(words * 8) do return -2
    write_word(output, 0, i64(query_count))
    for i := 0; i < query_count; i += 1 { write_word(output, i + 1, queries[i]) }
    write_word(output, query_count + 1, i64(size))
    write_word(output, query_count + 2, i64(capacity))
    for i := 0; i < size; i += 1 {
        if active == 0 { write_word(output, query_count + 3 + i, a[i]) }
        else { write_word(output, query_count + 3 + i, b[i]) }
    }
    return i64(words)
}
