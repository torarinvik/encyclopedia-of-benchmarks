package singly_link_list_deletion

import "core:c"

MAX_N :: 64
I32_MIN :: -2147483648
I32_MAX :: 2147483647

@(export, link_name="singly_link_list_deletion")
singly_link_list_deletion :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_N + 2) do return -1
    if input[0] < 1 || input[0] > MAX_N do return -1
    n := int(input[0])
    if length != c.size_t(n + 2) || input[1] < 1 || input[1] > i64(n) do return -1
    for i := 0; i < n; i += 1 {
        if input[i + 2] < I32_MIN || input[i + 2] > I32_MAX do return -1
    }
    bytes := c.size_t(4 * (n - 1))
    if output == nil || capacity < bytes do return -2

    nodes: [MAX_N]i32
    next: [MAX_N]int
    for i := 0; i < n; i += 1 {
        nodes[i] = i32(input[i + 2])
        next[i] = -1
        if i + 1 < n do next[i] = i + 1
    }
    head := 0
    position := int(input[1])
    if position == 1 do head = next[head]
    else {
        previous := head
        for i := 2; i < position; i += 1 do previous = next[previous]
        removed := next[previous]
        next[previous] = next[removed]
    }
    node := head
    for i := 0; i < n - 1; i += 1 {
        bits := transmute(u32)(nodes[node])
        for byte := 0; byte < 4; byte += 1 {
            output[i*4+byte] = u8((bits >> (8*byte)) & 255)
        }
        if i + 1 < n - 1 do node = next[node]
    }
    return i64(bytes)
}
