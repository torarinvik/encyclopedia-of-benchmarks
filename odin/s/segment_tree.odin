package segment_tree

import "core:c"

MAX_ITEMS :: 256
MAX_OPERATIONS :: 512
MAX_INPUT_VALUES :: MAX_ITEMS + 3 + 3 * MAX_OPERATIONS
VALUE_LIMIT :: i64(1_000_000)
QUERY_OFFSET :: i64(256_000_001)
FINAL_OFFSET :: i64(1_000_001)

identity :: proc "contextless" (mode: i64) -> i64 {
    if mode == 1 do return VALUE_LIMIT + 1
    if mode == 2 do return -(VALUE_LIMIT + 1)
    return 0
}

combine :: proc "contextless" (mode, left, right: i64) -> i64 {
    if mode == 1 do return min(left, right)
    if mode == 2 do return max(left, right)
    return left + right
}

@(export)
segment_tree_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 3 || length > MAX_INPUT_VALUES do return -1
    mode := values[0]
    item_count_value := values[1]
    if mode < 0 || mode > 2 || item_count_value < 1 || item_count_value > MAX_ITEMS do return -1
    item_count := int(item_count_value)
    if int(length) < item_count + 3 do return -1
    operation_count_value := values[item_count + 2]
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
    operation_count := int(operation_count_value)
    if int(length) != item_count + 3 + 3 * operation_count do return -1

    data: [MAX_ITEMS]i64
    for i := 0; i < item_count; i += 1 {
        value := values[i + 2]
        if value < -VALUE_LIMIT || value > VALUE_LIMIT do return -1
        data[i] = value
    }
    for operation := 0; operation < operation_count; operation += 1 {
        position := item_count + 3 + 3 * operation
        opcode := values[position]
        first := values[position + 1]
        second := values[position + 2]
        if opcode == 0 {
            if first < 0 || first >= item_count_value || second < -VALUE_LIMIT || second > VALUE_LIMIT do return -1
        } else if opcode == 1 {
            if first < 0 || second < first || second >= item_count_value do return -1
        } else {
            return -1
        }
    }

    base := 1
    for base < item_count { base *= 2 }
    empty := identity(mode)
    tree: [2 * MAX_ITEMS]i64
    for i := 0; i < 2 * base; i += 1 { tree[i] = empty }
    for i := 0; i < item_count; i += 1 { tree[base + i] = data[i] }
    node := base
    for node > 1 {
        node -= 1
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])
    }

    checksum: i64 = 0
    for operation := 0; operation < operation_count; operation += 1 {
        position := item_count + 3 + 3 * operation
        opcode := values[position]
        first := int(values[position + 1])
        if opcode == 0 {
            value := values[position + 2]
            data[first] = value
            node = base + first
            tree[node] = value
            for node > 1 {
                node /= 2
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])
            }
        } else {
            left := base + first
            right := base + int(values[position + 2]) + 1
            result := empty
            for left < right {
                if left % 2 == 1 {
                    result = combine(mode, result, tree[left])
                    left += 1
                }
                if right % 2 == 1 {
                    right -= 1
                    result = combine(mode, result, tree[right])
                }
                left /= 2
                right /= 2
            }
            checksum += i64(operation + 1) * (result + QUERY_OFFSET)
        }
    }
    for i := 0; i < item_count; i += 1 {
        checksum += i64(operation_count + i + 1) * (data[i] + FINAL_OFFSET)
    }
    return checksum
}

