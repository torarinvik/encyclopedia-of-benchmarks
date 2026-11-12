package point_set_range_sort_range_composite

import "core:c"

MODULUS :: i64(998244353)
MAX_LENGTH :: c.size_t(210)
MAX_PRIORITY :: i64(1_000_000_000)
Record :: struct { priority, a, b: i64 }

@(export)
point_set_range_sort_range_composite :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_LENGTH do return -1
    n_value, q_value := input[0], input[1]
    if n_value < 1 || n_value > 16 || q_value < 1 || q_value > 32 do return -1
    n, q := int(n_value), int(q_value)
    if int(length) < 2 + 3*n do return -1
    records: [16]Record
    seen: [48]i64
    seen_count, cursor := 0, 2
    for i := 0; i < n; i += 1 {
        p, a, b := input[cursor], input[cursor+1], input[cursor+2]
        cursor += 3
        if p < 0 || p > MAX_PRIORITY || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS do return -1
        for j := 0; j < seen_count; j += 1 { if seen[j] == p do return -1 }
        seen[seen_count] = p
        seen_count += 1
        records[i] = {p, a, b}
    }
    checksum, query_number: i64 = 0, 0
    for _ := 0; _ < q; _ += 1 {
        if cursor >= int(length) do return -1
        opcode := input[cursor]
        cursor += 1
        if opcode == 0 {
            if int(length)-cursor < 4 do return -1
            index, p, a, b := input[cursor], input[cursor+1], input[cursor+2], input[cursor+3]
            cursor += 4
            if index < 0 || index >= n_value || p < 0 || p > MAX_PRIORITY || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS do return -1
            for j := 0; j < seen_count; j += 1 { if seen[j] == p do return -1 }
            seen[seen_count] = p
            seen_count += 1
            records[int(index)] = {p, a, b}
        } else if opcode == 1 {
            if int(length)-cursor < 3 do return -1
            left, right, x := input[cursor], input[cursor+1], input[cursor+2]
            cursor += 3
            if left < 0 || left >= right || right > n_value || x < 0 || x >= MODULUS do return -1
            answer := x
            for i := int(left); i < int(right); i += 1 { answer = (records[i].a*answer + records[i].b) % MODULUS }
            query_number += 1
            checksum = (checksum + query_number*answer) % MODULUS
        } else if opcode == 2 || opcode == 3 {
            if int(length)-cursor < 2 do return -1
            left, right := input[cursor], input[cursor+1]
            cursor += 2
            if left < 0 || left >= right || right > n_value do return -1
            for i := int(left)+1; i < int(right); i += 1 {
                item := records[i]
                j := i
                for j > int(left) && ((opcode == 2 && records[j-1].priority > item.priority) || (opcode == 3 && records[j-1].priority < item.priority)) {
                    records[j] = records[j-1]
                    j -= 1
                }
                records[j] = item
            }
        } else do return -1
    }
    if cursor != int(length) do return -1
    return checksum
}
