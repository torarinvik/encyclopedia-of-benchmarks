package hypergraph_incidence_graph_encoding
import "core:c"

MAX_N :: 8
MAX_M :: 12
MAX_INPUT :: 111

put_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
hypergraph_incidence_graph_encoding :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 12 do return -1
    n, m := int(n64), int(m64)
    incidence: [MAX_N][MAX_M]bool
    offset := 2
    for edge := 0; edge < m; edge += 1 {
        if c.size_t(offset) >= length do return -1
        size64 := input[offset]
        offset += 1
        if size64 < 0 || size64 > n64 || c.size_t(size64) > length-c.size_t(offset) do return -1
        for item := 0; item < int(size64); item += 1 {
            vertex64 := input[offset]
            offset += 1
            if vertex64 < 0 || vertex64 >= n64 do return -1
            vertex := int(vertex64)
            if incidence[vertex][edge] do return -1
            incidence[vertex][edge] = true
        }
    }
    if c.size_t(offset) != length do return -1

    count := 0
    for vertex := 0; vertex < n; vertex += 1 {
        for edge := 0; edge < m; edge += 1 {
            if incidence[vertex][edge] do count += 1
        }
    }
    nodes := n + m
    bytes := 8 * (2 + nodes + 2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put_le(output, 0, i64(nodes))
    put_le(output, 8, i64(count))
    word := 2
    for vertex := 0; vertex < n; vertex += 1 { put_le(output, 8*word, 0); word += 1 }
    for edge := 0; edge < m; edge += 1 { put_le(output, 8*word, 1); word += 1 }
    for vertex := 0; vertex < n; vertex += 1 {
        for edge := 0; edge < m; edge += 1 {
            if incidence[vertex][edge] {
                put_le(output, 8*word, i64(vertex)); word += 1
                put_le(output, 8*word, i64(n+edge)); word += 1
            }
        }
    }
    return i64(bytes)
}
