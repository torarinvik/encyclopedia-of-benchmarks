package binary_indexed_tree

import "core:c"

MAX_ITEMS :: 256
MAX_OPERATIONS :: 512
MAX_INPUT_VALUES :: 2 + 3 * MAX_OPERATIONS
VALUE_LIMIT :: i64(1_000_000)
QUERY_OFFSET :: i64(131_072_000_001)
FINAL_OFFSET :: i64(512_000_001)

lowbit :: proc "contextless" (index: int) -> int { return index & -index }
prefix_sum :: proc "contextless" (tree: ^[MAX_ITEMS + 2]i32, initial: int) -> i32 {
    count := initial
    sum: i32 = 0
    for count > 0 { sum += tree[count]; count -= lowbit(count) }
    return sum
}

@(export)
binary_indexed_tree :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
    n_value := values[0]; op_value := values[1]
    if n_value < 2 || n_value > MAX_ITEMS || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > MAX_OPERATIONS do return -1
    n := int(n_value); operations := int(op_value)
    if length != c.size_t(2 + 3 * operations) do return -1
    for op := 0; op < operations; op += 1 {
        at := c.size_t(2 + 3 * op)
        code := values[at]; first := values[at + 1]; second := values[at + 2]
        if code == 0 { if first < 0 || first >= n_value || second < -VALUE_LIMIT || second > VALUE_LIMIT do return -1 }
        else if code == 1 { if first < 0 || second < first || second >= n_value do return -1 }
        else do return -1
    }
    var data: [MAX_ITEMS]i32
    var tree: [MAX_ITEMS + 2]i32
    checksum: i64 = 0
    for op := 0; op < operations; op += 1 {
        at := c.size_t(2 + 3 * op)
        code := values[at]; first := int(values[at + 1]); second := i32(values[at + 2])
        if code == 0 {
            data[first] += second
            start := first + 1
            for start <= n + 1 { tree[start] += second; start += lowbit(start) }
        } else {
            result := prefix_sum(&tree, int(second) + 1) - prefix_sum(&tree, first)
            checksum += i64(op + 1) * (i64(result) + QUERY_OFFSET)
        }
    }
    for i := 0; i < n; i += 1 { checksum += i64(operations + i + 1) * (i64(data[i]) + FINAL_OFFSET) }
    return checksum
}
