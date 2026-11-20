package edge_colored_graph_layer_encoding
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 97
MAX_VERTICES :: 24

put_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
edge_colored_graph_layer_encoding :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > MAX_INPUT do return -1
    n0, m0, d0, q0 := input[0], input[1], input[2], input[3]
    if n0 < 1 || n0 > 8 || m0 < 0 || m0 > 28 || d0 < 1 || d0 > 3 || q0 < 1 || q0 > 3 do return -1
    n, m, layers, classes := int(n0), int(m0), int(d0), int(q0)
    edge_offset := 4 + n
    if int(length) != edge_offset + 3*m do return -1
    source_colors: [MAX_N]i64
    for vertex := 0; vertex < n; vertex += 1 {
        source_colors[vertex] = input[4+vertex]
        if source_colors[vertex] < 0 || source_colors[vertex] >= q0 do return -1
    }
    source_edges: [MAX_N][MAX_N]u8
    offset := edge_offset
    for edge := 0; edge < m; edge += 1 {
        u0, v0, color0 := input[offset], input[offset+1], input[offset+2]
        offset += 3
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || color0 < 1 || color0 >= (1 << d0) do return -1
        u, v := int(u0), int(v0)
        if u > v { u, v = v, u }
        if source_edges[u][v] != 0 do return -1
        source_edges[u][v] = u8(color0)
    }

    nodes := n * layers
    adjacency: [MAX_VERTICES][MAX_VERTICES]bool
    for layer := 0; layer < layers; layer += 1 {
        bit := u8(1 << layer)
        for u := 0; u < n; u += 1 {
            for v := u+1; v < n; v += 1 {
                if (source_edges[u][v] & bit) != 0 do adjacency[layer*n+u][layer*n+v] = true
            }
        }
    }
    for vertex := 0; vertex < n; vertex += 1 {
        for layer := 0; layer+1 < layers; layer += 1 {
            adjacency[layer*n+vertex][(layer+1)*n+vertex] = true
        }
    }
    edge_count := 0
    for u := 0; u < nodes; u += 1 {
        for v := u+1; v < nodes; v += 1 {
            if adjacency[u][v] do edge_count += 1
        }
    }
    bytes := 8 * (2 + nodes + 2*edge_count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put_le(output, 0, i64(nodes))
    put_le(output, 8, i64(edge_count))
    word := 2
    for layer := 0; layer < layers; layer += 1 {
        for vertex := 0; vertex < n; vertex += 1 {
            put_le(output, 8*word, i64(layer*classes)+source_colors[vertex]); word += 1
        }
    }
    for u := 0; u < nodes; u += 1 {
        for v := u+1; v < nodes; v += 1 {
            if adjacency[u][v] {
                put_le(output, 8*word, i64(u)); word += 1
                put_le(output, 8*word, i64(v)); word += 1
            }
        }
    }
    return i64(bytes)
}
