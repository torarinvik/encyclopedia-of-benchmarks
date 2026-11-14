package xor_filter_peeling

import "core:c"

@(export)
xor_filter_peeling :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 259 || input[0] < 0 || input[0] > 32 || input[1] < 3 || input[1] > 96 || input[2] < 0 || input[2] > 32 { return -1 }
    n, slots, q := int(input[0]), int(input[1]), int(input[2])
    if int(length) != 3+4*(n+q) { return -1 }
    for i := 0; i < n+q; i += 1 {
        at := 3+4*i
        a, b, c, f := input[at], input[at+1], input[at+2], input[at+3]
        if a < 0 || a >= i64(slots) || b < 0 || b >= i64(slots) || c < 0 || c >= i64(slots) || a == b || a == c || b == c || f < 0 || f > 255 { return -1 }
    }
    degree, edge_xor, queue, table: [96]int
    stack_slot, stack_edge: [32]int
    for edge := 0; edge < n; edge += 1 {
        for j := 0; j < 3; j += 1 {
            slot := int(input[3+4*edge+j])
            degree[slot] += 1
            edge_xor[slot] ~= edge
        }
    }
    head, tail, used := 0, 0, 0
    for slot := 0; slot < slots; slot += 1 {
        if degree[slot] == 1 { queue[tail] = slot; tail += 1 }
    }
    for head < tail {
        slot := queue[head]
        head += 1
        if degree[slot] != 1 { continue }
        edge := edge_xor[slot]
        stack_slot[used] = slot
        stack_edge[used] = edge
        used += 1
        for j := 0; j < 3; j += 1 {
            v := int(input[3+4*edge+j])
            degree[v] -= 1
            edge_xor[v] ~= edge
            if degree[v] == 1 { queue[tail] = v; tail += 1 }
        }
    }
    if used != n { return -2 }
    for used > 0 {
        used -= 1
        at := 3+4*stack_edge[used]
        a, b, c := int(input[at]), int(input[at+1]), int(input[at+2])
        table[stack_slot[used]] = int(input[at+3]) ~ table[a] ~ table[b] ~ table[c]
    }
    result: i64 = 0
    for i := 0; i < q; i += 1 {
        at := 3+4*(n+i)
        a, b, c := int(input[at]), int(input[at+1]), int(input[at+2])
        if table[a] ~ table[b] ~ table[c] == int(input[at+3]) { result += i64(i+1) }
    }
    return result
}
