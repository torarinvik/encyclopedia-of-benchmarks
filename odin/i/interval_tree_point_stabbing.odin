package interval_tree_point_stabbing

import "core:c"

MAX_N :: 16
MAX_Q :: 8
TREE_CAP :: 32
MAX_OUTPUT :: 72

Interval :: struct { low, high: i64, id: int }

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
interval_tree_point_stabbing :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 43 do return -1
    n64, q64 := input[0], input[1]
    if n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q do return -1
    n, q := int(n64), int(q64)
    if length != c.size_t(2 + 2 * n + q) do return -1
    sorted: [MAX_N]Interval
    cursor := 2
    for id := 0; id < n; id += 1 {
        low, high := input[cursor], input[cursor + 1]
        cursor += 2
        if low < -32 || low > 32 || high < -32 || high > 32 || low > high do return -1
        sorted[id] = {low, high, id}
    }
    points: [MAX_Q]i64
    for i := 0; i < q; i += 1 {
        points[i] = input[cursor]
        cursor += 1
        if points[i] < -32 || points[i] > 32 do return -1
    }
    for i := 1; i < n; i += 1 {
        value := sorted[i]
        j := i
        for j > 0 {
            previous := sorted[j - 1]
            greater := previous.low > value.low ||
                (previous.low == value.low && previous.high > value.high) ||
                (previous.low == value.low && previous.high == value.high && previous.id > value.id)
            if !greater do break
            sorted[j] = previous
            j -= 1
        }
        sorted[j] = value
    }
    tree: [TREE_CAP]Interval
    used: [TREE_CAP]bool
    maximum: [TREE_CAP]i64
    firsts, lasts: [MAX_N]int
    nodes: [MAX_N]int
    for i := 0; i < TREE_CAP; i += 1 {
        maximum[i] = -9223372036854775807 - 1
        used[i] = false
    }
    if n > 0 {
        top := 1
        firsts[0], lasts[0], nodes[0] = 0, n - 1, 0
        for top > 0 {
            top -= 1
            first, last, node := firsts[top], lasts[top], nodes[top]
            if first > last || node >= TREE_CAP do continue
            middle := first + (last - first) / 2
            tree[node] = sorted[middle]
            used[node] = true
            if middle + 1 <= last { firsts[top], lasts[top], nodes[top] = middle + 1, last, 2 * node + 2; top += 1 }
            if first <= middle - 1 { firsts[top], lasts[top], nodes[top] = first, middle - 1, 2 * node + 1; top += 1 }
        }
    }
    for node := TREE_CAP - 1; node >= 0; node -= 1 {
        if !used[node] do continue
        maximum[node] = tree[node].high
        left, right := 2 * node + 1, 2 * node + 2
        if left < TREE_CAP && used[left] && maximum[left] > maximum[node] do maximum[node] = maximum[left]
        if right < TREE_CAP && used[right] && maximum[right] > maximum[node] do maximum[node] = maximum[right]
    }
    masks: [MAX_Q]i64
    for qi := 0; qi < q; qi += 1 {
        stack: [TREE_CAP]int
        top := 0
        if n > 0 { stack[0] = 0; top = 1 }
        for top > 0 {
            top -= 1
            node := stack[top]
            if !used[node] || maximum[node] < points[qi] do continue
            left, right := 2 * node + 1, 2 * node + 2
            if left < TREE_CAP && used[left] && maximum[left] >= points[qi] { stack[top] = left; top += 1 }
            if tree[node].low <= points[qi] && points[qi] <= tree[node].high { masks[qi] |= i64(1) << tree[node].id }
            if tree[node].low <= points[qi] && right < TREE_CAP && used[right] && maximum[right] >= points[qi] { stack[top] = right; top += 1 }
        }
    }
    bytes := c.size_t((q + 1) * 8)
    if output == nil || capacity < bytes do return -2
    staged: [MAX_OUTPUT]u8
    write_i64_le(&staged[0], 0, q)
    for i := 0; i < q; i += 1 { write_i64_le(&staged[0], (i + 1) * 8, masks[i]) }
    for i := c.size_t(0); i < bytes; i += 1 { output[i] = staged[i] }
    return i64(bytes)
}
