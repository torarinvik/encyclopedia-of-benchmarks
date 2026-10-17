package minimum_spanning_tree_kruskal2

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 64
MAX_INPUT_WORDS :: 194
MAX_OUTPUT_WORDS :: 1 + 3 * (MAX_VERTICES - 1)
MAX_OUTPUT_BYTES :: 4 * MAX_OUTPUT_WORDS

Edge :: struct { u, v, weight: i32 }

find_root :: proc "contextless" (parent: [^]i32, node: i32) -> i32 {
    current := node
    for parent[current] != current {
        parent[current] = parent[parent[current]]
        current = parent[current]
    }
    return current
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
minimum_spanning_tree_kruskal2 :: proc "c" (input: [^]i32, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_WORDS) do return -1
    vertex_count := input[0]
    edge_count := input[1]
    if vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count < 0 || edge_count > MAX_EDGES do return -1
    if int(length) != 2 + 3 * int(edge_count) do return -1

    input_edges: [MAX_EDGES]Edge
    seen: [MAX_VERTICES][MAX_VERTICES]bool
    pos := 2
    for i := 0; i < int(edge_count); i += 1 {
        u, v, weight := input[pos], input[pos+1], input[pos+2]
        pos += 3
        if u < 0 || v <= u || v >= vertex_count || seen[u][v] do return -1
        seen[u][v] = true
        input_edges[i] = Edge{u=u, v=v, weight=weight}
    }

    visited: [MAX_VERTICES]bool
    stack: [MAX_VERTICES]int
    stack_size := 1
    reached := 0
    stack[0] = 0
    visited[0] = true
    for stack_size > 0 {
        stack_size -= 1
        node := stack[stack_size]
        reached += 1
        for neighbor := 0; neighbor < int(vertex_count); neighbor += 1 {
            if (seen[node][neighbor] || seen[neighbor][node]) && !visited[neighbor] {
                visited[neighbor] = true
                stack[stack_size] = neighbor
                stack_size += 1
            }
        }
    }
    if reached != int(vertex_count) do return -1

    ordered: [MAX_EDGES]Edge
    ordered_count := 0
    for u := 0; u < int(vertex_count); u += 1 {
        for i := 0; i < int(edge_count); i += 1 {
            if input_edges[i].u == i32(u) { ordered[ordered_count] = input_edges[i]; ordered_count += 1 }
        }
    }
    for i := 1; i < ordered_count; i += 1 {
        key := ordered[i]
        j := i
        for j > 0 && ordered[j-1].weight > key.weight { ordered[j] = ordered[j-1]; j -= 1 }
        ordered[j] = key
    }

    parent: [MAX_VERTICES]i32
    rank: [MAX_VERTICES]int
    for i := 0; i < int(vertex_count); i += 1 { parent[i] = i32(i) }
    words: [MAX_OUTPUT_WORDS]i32
    word_count := 1
    accepted := 0
    for i := 0; i < ordered_count && accepted < int(vertex_count-1); i += 1 {
        root_u := find_root(&parent[0], ordered[i].u)
        root_v := find_root(&parent[0], ordered[i].v)
        if root_u == root_v do continue
        if rank[root_u] < rank[root_v] do parent[root_u] = root_v
        else if rank[root_u] > rank[root_v] do parent[root_v] = root_u
        else { parent[root_u] = root_v; rank[root_v] += 1 }
        words[word_count] = ordered[i].u
        words[word_count+1] = ordered[i].v
        words[word_count+2] = ordered[i].weight
        word_count += 3
        accepted += 1
    }
    if accepted != int(vertex_count-1) do return -1
    words[0] = i32(accepted)
    bytes := word_count * 4
    if output == nil || capacity < c.size_t(bytes) do return -2
    buffer: [MAX_OUTPUT_BYTES]u8
    for i := 0; i < word_count; i += 1 { put_i32_le(&buffer[0], i*4, words[i]) }
    for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
    return i64(bytes)
}
