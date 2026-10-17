package prufer_code

import "core:c"

MAX_VERTICES :: 64
MAX_OUTPUT_BYTES :: 1016

write_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := u64(value)
    for byte: usize = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

make_code :: proc "contextless" (input: [^]i64, n: usize, code: [^]i64) -> i64 {
    adjacency: [4096]bool = {}
    degree: [64]usize = {}
    for edge: usize = 0; edge + 1 < n; edge += 1 {
        raw_u, raw_v := input[2 + edge * 2], input[3 + edge * 2]
        if raw_u < 0 || raw_v < 0 || raw_u >= i64(n) || raw_v >= i64(n) || raw_u == raw_v do return -1
        u, v := usize(raw_u), usize(raw_v)
        if adjacency[u * 64 + v] do return -1
        adjacency[u * 64 + v] = true
        adjacency[v * 64 + u] = true
        degree[u] += 1
        degree[v] += 1
    }
    visited: [64]bool = {}
    queue: [64]usize = {}
    head, tail: usize = 0, 0
    visited[0] = true
    queue[tail] = 0
    tail += 1
    for head < tail {
        u := queue[head]
        head += 1
        for v: usize = 0; v < n; v += 1 {
            if adjacency[u * 64 + v] && !visited[v] {
                visited[v] = true
                queue[tail] = v
                tail += 1
            }
        }
    }
    if tail != n do return -1
    active: [64]bool = {}
    for v: usize = 0; v < n; v += 1 do active[v] = true
    code_length: usize = 0
    for step: usize = 0; step + 2 < n; step += 1 {
        leaf: usize = n
        for v: usize = n; v > 0; v -= 1 {
            candidate := v - 1
            if active[candidate] && degree[candidate] == 1 { leaf = candidate; break }
        }
        if leaf == n do return -1
        neighbor: usize = n
        for v: usize = 0; v < n; v += 1 {
            if active[v] && adjacency[leaf * 64 + v] { neighbor = v; break }
        }
        if neighbor == n do return -1
        code[code_length] = i64(neighbor)
        code_length += 1
        active[leaf] = false
        adjacency[leaf * 64 + neighbor] = false
        adjacency[neighbor * 64 + leaf] = false
        degree[neighbor] -= 1
    }
    return i64(code_length)
}

add_edge :: proc "contextless" (edges: [^]i64, index, u, v: usize) {
    edges[index * 2] = i64(min(u, v))
    edges[index * 2 + 1] = i64(max(u, v))
}

make_decoded_edges :: proc "contextless" (input: [^]i64, n: usize, edges: [^]i64) -> i64 {
    remaining: [64]usize = {}
    for i: usize = 0; i + 2 < n; i += 1 {
        raw := input[2 + i]
        if raw < 0 || raw >= i64(n) do return -1
        remaining[usize(raw)] += 1
    }
    active: [64]bool = {}
    for v: usize = 0; v < n; v += 1 do active[v] = true
    edge_count: usize = 0
    for i: usize = 0; i + 2 < n; i += 1 {
        leaf: usize = n
        for v: usize = n; v > 0; v -= 1 {
            candidate := v - 1
            if active[candidate] && remaining[candidate] == 0 { leaf = candidate; break }
        }
        if leaf == n do return -1
        vertex := usize(input[2 + i])
        add_edge(edges, edge_count, leaf, vertex)
        edge_count += 1
        active[leaf] = false
        remaining[vertex] -= 1
    }
    first: usize = n
    for v: usize = n; v > 0; v -= 1 { if active[v - 1] { first = v - 1; break } }
    if first == n do return -1
    active[first] = false
    second: usize = n
    for v: usize = n; v > 0; v -= 1 { if active[v - 1] { second = v - 1; break } }
    if second == n do return -1
    add_edge(edges, edge_count, first, second)
    edge_count += 1
    for i: usize = 1; i < edge_count; i += 1 {
        u, v := edges[i * 2], edges[i * 2 + 1]
        j := i
        for j > 0 && (edges[(j - 1) * 2] > u ||
            (edges[(j - 1) * 2] == u && edges[(j - 1) * 2 + 1] > v)) {
            edges[j * 2] = edges[(j - 1) * 2]
            edges[j * 2 + 1] = edges[(j - 1) * 2 + 1]
            j -= 1
        }
        edges[j * 2] = u
        edges[j * 2 + 1] = v
    }
    return i64(edge_count)
}

@(export, link_name="prufer_code")
prufer_code :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 129 do return -1
    mode, raw_n := input[0], input[1]
    if raw_n < 1 || raw_n > MAX_VERTICES || (mode != 0 && mode != 1) do return -1
    n := usize(raw_n)
    if mode == 0 {
        if length != c.size_t(2 * n) do return -1
        code: [64]i64 = {}
        code_length := make_code(input, n, &code[0])
        if code_length < 0 do return -1
        needed := usize(code_length) * 8
        if needed == 0 do return 0
        if output == nil || capacity < c.size_t(needed) do return -2
        for i: usize = 0; i < usize(code_length); i += 1 do write_i64_le(output, i * 8, code[i])
        return i64(needed)
    }
    if n < 2 || length != c.size_t(n) do return -1
    edges: [126]i64 = {}
    edge_count := make_decoded_edges(input, n, &edges[0])
    if edge_count < 0 do return -1
    needed := 8 + usize(edge_count) * 16
    if needed > MAX_OUTPUT_BYTES do return -1
    if output == nil || capacity < c.size_t(needed) do return -2
    write_i64_le(output, 0, edge_count)
    for i: usize = 0; i < usize(edge_count); i += 1 {
        write_i64_le(output, 8 + i * 16, edges[i * 2])
        write_i64_le(output, 16 + i * 16, edges[i * 2 + 1])
    }
    return i64(needed)
}
