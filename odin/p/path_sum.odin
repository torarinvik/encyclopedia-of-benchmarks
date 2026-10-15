package path_sum

import "core:c"

MAX_NODES :: 63

path_has_sum :: proc "contextless" (input: [^]i64, node: int, sum, target: i64) -> bool {
    base := 2 + 3 * node
    next_sum := sum + input[base]
    left, right := input[base + 1], input[base + 2]
    if left == -1 && right == -1 do return next_sum == target
    return (left != -1 && path_has_sum(input, int(left), next_sum, target)) ||
        (right != -1 && path_has_sum(input, int(right), next_sum, target))
}

@(export)
path_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || input[1] < 0 || input[1] > MAX_NODES do return -1
    count := int(input[1])
    if length != c.size_t(2 + 3 * count) do return -1
    if count == 0 do return 0
    for index := 0; index < count; index += 1 {
        base := 2 + 3 * index
        if input[base] < -2147483648 || input[base] > 2147483647 do return -1
        for edge := 1; edge <= 2; edge += 1 {
            if input[base + edge] < -1 || input[base + edge] >= i64(count) do return -1
        }
    }
    seen: [MAX_NODES]bool
    stack: [MAX_NODES]int
    top := 1
    visited := 0
    stack[0] = 0
    for top > 0 {
        top -= 1
        node := stack[top]
        if seen[node] do return -1
        seen[node] = true
        visited += 1
        base := 2 + 3 * node
        left, right := input[base + 1], input[base + 2]
        if left != -1 { stack[top] = int(left); top += 1 }
        if right != -1 { stack[top] = int(right); top += 1 }
    }
    if visited != count do return -1
    if path_has_sum(input, 0, 0, input[0]) do return 1
    return 0
}
