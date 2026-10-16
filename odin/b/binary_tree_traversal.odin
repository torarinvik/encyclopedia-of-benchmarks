package binary_tree_traversal

import "core:c"

MAX_NODES :: 64
MAX_INPUT_LENGTH :: 3 + 3 * MAX_NODES

walk :: proc "contextless" (order: i64, values, left, right: ^[MAX_NODES]i64, node: int, output: ^[MAX_NODES]i64, used: ^int) {
    if order == 0 { output[used^] = values[node]; used^ += 1 }
    if left[node] >= 0 { walk(order, values, left, right, int(left[node]), output, used) }
    if order == 1 { output[used^] = values[node]; used^ += 1 }
    if right[node] >= 0 { walk(order, values, left, right, int(right[node]), output, used) }
    if order == 2 { output[used^] = values[node]; used^ += 1 }
}

breadth_first :: proc "contextless" (order: i64, values, left, right: ^[MAX_NODES]i64, root: int, output: ^[MAX_NODES]i64, used: ^int) {
    queue: [MAX_NODES]int
    head := 0
    tail := 1
    queue[0] = root
    for head < tail {
        node := queue[head]
        head += 1
        output[used^] = values[node]
        used^ += 1
        first := left[node]
        second := right[node]
        if order == 4 { first = right[node]; second = left[node] }
        if first >= 0 { queue[tail] = int(first); tail += 1 }
        if second >= 0 { queue[tail] = int(second); tail += 1 }
    }
}

breadth_first_zigzag :: proc "contextless" (values, left, right: ^[MAX_NODES]i64, root: int, output: ^[MAX_NODES]i64, used: ^int) {
    queue: [MAX_NODES]int
    head := 0
    tail := 1
    level := 0
    queue[0] = root
    for head < tail {
        level_end := tail
        level_start := used^
        for head < level_end {
            node := queue[head]
            head += 1
            output[used^] = values[node]
            used^ += 1
            if left[node] >= 0 { queue[tail] = int(left[node]); tail += 1 }
            if right[node] >= 0 { queue[tail] = int(right[node]); tail += 1 }
        }
        if level % 2 == 1 {
            lo := level_start
            hi := used^ - 1
            for lo < hi {
                value := output[lo]
                output[lo] = output[hi]
                output[hi] = value
                lo += 1
                hi -= 1
            }
        }
        level += 1
    }
}

mark_reachable :: proc "contextless" (left, right: ^[MAX_NODES]i64, root: int, seen: ^[MAX_NODES]bool) -> int {
    stack: [MAX_NODES]int
    top := 1
    count := 0
    stack[0] = root
    for top > 0 {
        top -= 1
        node := stack[top]
        if seen[node] { continue }
        seen[node] = true
        count += 1
        if right[node] >= 0 { stack[top] = int(right[node]); top += 1 }
        if left[node] >= 0 { stack[top] = int(left[node]); top += 1 }
    }
    return count
}

put_i64 :: proc "contextless" (output: [^]u8, index: c.size_t, value: i64) {
    bits := u64(value)
    for byte := c.size_t(0); byte < 8; byte += 1 { output[index * 8 + byte] = u8(bits >> (8 * byte)) }
}

@(export)
binary_tree_traversal :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
    order := input[0]; count_value := input[1]; root_value := input[2]
    if order < 0 || order > 6 || count_value < 0 || count_value > MAX_NODES do return -1
    n := int(count_value)
    if length != c.size_t(3 + 3 * n) || (n == 0 && root_value != -1) || (n > 0 && (root_value < 0 || root_value >= i64(n))) do return -1
    values: [MAX_NODES]i64
    left: [MAX_NODES]i64
    right: [MAX_NODES]i64
    parents: [MAX_NODES]u8
    for i := 0; i < n; i += 1 {
        values[i] = input[3 + 3 * i]
        left[i] = input[4 + 3 * i]
        right[i] = input[5 + 3 * i]
        if left[i] < -1 || left[i] >= i64(n) || right[i] < -1 || right[i] >= i64(n) || left[i] == i64(i) || right[i] == i64(i) do return -1
        if left[i] >= 0 { parents[int(left[i])] += 1; if parents[int(left[i])] > 1 do return -1 }
        if right[i] >= 0 { parents[int(right[i])] += 1; if parents[int(right[i])] > 1 do return -1 }
    }
    result: [MAX_NODES]i64
    used := 0
    if n > 0 {
        root := int(root_value)
        for i := 0; i < n; i += 1 { expected := u8(1); if i == root { expected = 0 }; if parents[i] != expected do return -1 }
        seen: [MAX_NODES]bool
        if mark_reachable(&left, &right, root, &seen) != n do return -1
        if order <= 2 { walk(order, &values, &left, &right, root, &result, &used) }
        else if order == 5 { walk(1, &values, &right, &left, root, &result, &used) }
        else if order == 6 { breadth_first_zigzag(&values, &left, &right, root, &result, &used) }
        else { breadth_first(order, &values, &left, &right, root, &result, &used) }
    }
    if output == nil || capacity < c.size_t(used * 8) do return -2
    for i := 0; i < used; i += 1 { put_i64(output, c.size_t(i), result[i]) }
    return i64(used * 8)
}
