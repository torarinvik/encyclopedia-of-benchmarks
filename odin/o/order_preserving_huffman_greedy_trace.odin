package order_preserving_huffman_greedy_trace

import "core:c"

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for b := 0; b < 8; b += 1 { output[offset + b] = u8(bits >> (8 * b)) }
}

@(export)
order_preserving_huffman_greedy_trace :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 10 do return -1
    raw_n := input[0]
    if raw_n < 2 || raw_n > 8 || length != c.size_t(raw_n + 1) do return -1
    n := int(raw_n)
    weights: [15]i64
    left, right: [15]int
    active: [8]int
    for i := 0; i < 15; i += 1 { left[i] = -1; right[i] = -1 }
    total: i64 = 0
    for i := 0; i < n; i += 1 {
        w := input[i + 1]
        if w < 1 || w > 15 do return -1
        weights[i] = w; total += w; active[i] = i
    }
    if total > 120 do return -1
    count, next_node := n, n
    for count > 1 {
        pair := 0
        best := weights[active[0]] + weights[active[1]]
        for i := 1; i + 1 < count; i += 1 {
            candidate := weights[active[i]] + weights[active[i + 1]]
            if candidate < best { pair = i; best = candidate }
        }
        a, b := active[pair], active[pair + 1]
        weights[next_node] = best; left[next_node] = a; right[next_node] = b
        for i := pair; i + 2 < count; i += 1 { active[i] = active[i + 2] }
        count -= 2
        for i := count; i > pair; i -= 1 { active[i] = active[i - 1] }
        active[pair] = next_node
        count += 1; next_node += 1
    }
    depths: [8]i64
    stack_node, stack_depth: [16]int
    top := 1
    stack_node[0] = active[0]
    stack_depth[0] = 0
    for top > 0 {
        top -= 1
        node, depth := stack_node[top], stack_depth[top]
        if node < n { depths[node] = i64(depth) }
        else {
            stack_node[top] = left[node]; stack_depth[top] = depth + 1; top += 1
            stack_node[top] = right[node]; stack_depth[top] = depth + 1; top += 1
        }
    }
    words: [10]i64
    words[0] = raw_n
    for i := 0; i < n; i += 1 { words[1] += input[i + 1] * depths[i]; words[i + 2] = depths[i] }
    needed := 8 * (n + 2)
    staged: [80]u8
    for i := 0; i < n + 2; i += 1 { put_i64(&staged[0], 8 * i, words[i]) }
    if output == nil || capacity < c.size_t(needed) do return -2
    for i := 0; i < needed; i += 1 { output[i] = staged[i] }
    return i64(needed)
}
