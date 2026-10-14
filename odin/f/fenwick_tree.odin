package fenwick_tree

import "core:c"

MAX_ITEMS :: 256
MAX_OPERATIONS :: 512
MAX_INPUT_VALUES :: 2 + 3 * MAX_OPERATIONS
VALUE_LIMIT :: i64(1_000_000)
QUERY_OFFSET :: i64(131_072_000_001)
FINAL_OFFSET :: i64(512_000_001)

lowbit :: proc "contextless" (index: int) -> int { return index & -index }

prefix_sum :: proc "contextless" (tree: [^]i64, count: int) -> i64 {
    index := count
    sum := i64(0)
    for index > 0 {
        sum += tree[index]
        index -= lowbit(index)
    }
    return sum
}

@(export)
fenwick_tree_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES do return -1
    item_count_value := values[0]
    operation_count_value := values[1]
    if item_count_value < 1 || item_count_value > MAX_ITEMS do return -1
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
    item_count := int(item_count_value)
    operation_count := int(operation_count_value)
    if int(length) != 2 + 3 * operation_count do return -1
    for operation := 0; operation < operation_count; operation += 1 {
        position := 2 + 3 * operation
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

    data: [MAX_ITEMS]i64
    tree: [MAX_ITEMS + 1]i64
    for i := 0; i < item_count; i += 1 { data[i] = 0 }
    for i := 0; i <= item_count; i += 1 { tree[i] = 0 }
    checksum := i64(0)
    for operation := 0; operation < operation_count; operation += 1 {
        position := 2 + 3 * operation
        opcode := values[position]
        first := int(values[position + 1])
        second := values[position + 2]
        if opcode == 0 {
            data[first] += second
            for index := first + 1; index <= item_count; index += lowbit(index) { tree[index] += second }
        } else {
            right := int(second)
            result := prefix_sum(&tree[0], right + 1) - prefix_sum(&tree[0], first)
            checksum += i64(operation + 1) * (result + QUERY_OFFSET)
        }
    }
    for i := 0; i < item_count; i += 1 {
        checksum += i64(operation_count + i + 1) * (data[i] + FINAL_OFFSET)
    }
    return checksum
}
