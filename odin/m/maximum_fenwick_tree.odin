package maximum_fenwick_tree

import "core:c"

previous_bucket :: proc(index: i64) -> i64 { return (index & (index + 1)) - 1 }

@(export)
maximum_fenwick_tree :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 194 do return -1
    if input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 64 do return -1
    size := c.size_t(input[0]); op_count := c.size_t(input[1])
    if length != 2 + 3 * op_count do return -1
    values: [64]i32
    tree: [64]i32
    results: [64]i64
    result_count: c.size_t = 0
    for op: c.size_t = 0; op < op_count; op += 1 {
        pos := 2 + 3 * op
        opcode, first, second := input[pos], input[pos+1], input[pos+2]
        if opcode == 0 {
            if first < 0 || first >= i64(size) || second < 0 || second > 2_147_483_647 do return -1
            index := c.size_t(first)
            old_value, value := values[index], i32(second)
            values[index] = value
            for index < size {
                old_max := tree[index]
                if value > old_max {
                    tree[index] = value
                } else if old_value == old_max {
                    left := c.size_t(previous_bucket(i64(index)) + 1)
                    maximum := value
                    child := i64(index) - 1
                    for child >= i64(left) {
                        maximum = max(maximum, tree[c.size_t(child)])
                        if maximum == old_max do break
                        child = previous_bucket(child)
                    }
                    tree[index] = maximum
                    if maximum == old_max do break
                } else do break
                index |= index + 1
            }
        } else if opcode == 1 {
            if first < 0 || first > second || second > i64(size) do return -1
            maximum: i32 = 0
            right := second - 1
            for first <= right {
                current_left := right & (right + 1)
                if first <= current_left {
                    maximum = max(maximum, tree[c.size_t(right)])
                    right = current_left - 1
                } else {
                    maximum = max(maximum, values[c.size_t(right)])
                    right -= 1
                }
            }
            results[result_count] = i64(maximum)
            result_count += 1
        } else do return -1
    }
    bytes := result_count * 8
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < result_count; i += 1 {
        bits := u64(results[i])
        for b: c.size_t = 0; b < 8; b += 1 { output[8*i+b] = u8((bits >> (8*b)) & 255) }
    }
    return i64(bytes)
}
