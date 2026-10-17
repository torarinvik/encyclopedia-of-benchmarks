package rotate_singly_linked_lists

import "core:c"

MAX_N :: 64
I32_MIN :: -2147483648
I32_MAX :: 2147483647

@(export, link_name="rotate_singly_linked_lists")
rotate_singly_linked_lists :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_N + 2) do return -1
    if input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > I32_MAX do return -1
    n := int(input[0])
    k := input[1]
    if length != c.size_t(n + 2) do return -1
    for i := 0; i < n; i += 1 { if input[i + 2] < I32_MIN || input[i + 2] > I32_MAX do return -1 }
    bytes := c.size_t(8 * (n + 1))
    if output == nil || capacity < bytes do return -2

    nodes: [MAX_N]i32
    next: [MAX_N]int
    for i := 0; i < n; i += 1 {
        nodes[i] = i32(input[i + 2])
        next[i] = -1
        if i + 1 < n do next[i] = i + 1
    }
    head := -1
    if n > 0 do head = 0
    if n > 1 && k > 0 {
        tail := n - 1
        next[tail] = head
        shift := int(k % i64(n))
        steps := n - shift
        new_tail := tail
        for i := 0; i < steps; i += 1 { new_tail = next[new_tail] }
        head = next[new_tail]
        next[new_tail] = -1
    }
    count := u64(n)
    for byte := 0; byte < 8; byte += 1 { output[byte] = u8((count >> (byte * 8)) & 255) }
    node := head
    for i := 0; i < n; i += 1 {
        bits := transmute(u64)(i64(nodes[node]))
        for byte := 0; byte < 8; byte += 1 { output[8+i*8+byte] = u8((bits >> (byte*8)) & 255) }
        if i + 1 < n do node = next[node]
    }
    return i64(bytes)
}
