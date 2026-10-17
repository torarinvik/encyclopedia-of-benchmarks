package merge_sorted_singly_linked_list

import "core:c"

MAX_NODES :: 128
MAX_INPUT_LENGTH :: 130
MAX_OUTPUT_BYTES :: 1536

List_Node :: struct { value: i32, next: i32, origin: i32, position: i32 }

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
merge_sorted_singly_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if input[0] < 0 || input[0] > MAX_NODES do return -1
    len_a := int(input[0])
    if len_a > int(length)-2 do return -1
    len_b_pos := 1 + len_a
    raw_len_b := input[len_b_pos]
    if raw_len_b < 0 || raw_len_b > i64(MAX_NODES-len_a) do return -1
    len_b := int(raw_len_b)
    total := len_a + len_b
    if int(length) != 2 + total do return -1

    nodes: [MAX_NODES]List_Node
    for i := 0; i < len_a; i += 1 {
        raw := input[1+i]
        if raw < -2_147_483_648 || raw > 2_147_483_647 || (i > 0 && input[i] > raw) do return -1
        next := -1
        if i+1 < len_a do next = i32(i+1)
        nodes[i] = List_Node{value = i32(raw), next = next, origin = 0, position = i32(i)}
    }
    b_start := len_b_pos + 1
    for i := 0; i < len_b; i += 1 {
        raw := input[b_start+i]
        if raw < -2_147_483_648 || raw > 2_147_483_647 || (i > 0 && input[b_start+i-1] > raw) do return -1
        node := len_a + i
        next := -1
        if i+1 < len_b do next = i32(node+1)
        nodes[node] = List_Node{value = i32(raw), next = next, origin = 1, position = i32(i)}
    }

    head_a := if len_a == 0 do -1 else 0
    head_b := if len_b == 0 do -1 else len_a
    merged_head, tail: i32 = -1, -1
    for head_a >= 0 && head_b >= 0 {
        node: i32
        if nodes[head_a].value <= nodes[head_b].value {
            node = head_a
            head_a = nodes[node].next
        } else {
            node = head_b
            head_b = nodes[node].next
        }
        if tail < 0 do merged_head = node
        else do nodes[tail].next = node
        tail = node
    }
    remainder := if head_a >= 0 do head_a else head_b
    if tail < 0 do merged_head = remainder
    else do nodes[tail].next = remainder

    output_bytes := 12 * total
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    buffer: [MAX_OUTPUT_BYTES]u8
    written := 0
    node := merged_head
    for node >= 0 {
        item := nodes[node]
        put_i32_le(&buffer[0], written, item.value)
        put_i32_le(&buffer[0], written+4, item.origin)
        put_i32_le(&buffer[0], written+8, item.position)
        written += 12
        node = item.next
    }
    for i := 0; i < output_bytes; i += 1 { output[i] = buffer[i] }
    return i64(output_bytes)
}
