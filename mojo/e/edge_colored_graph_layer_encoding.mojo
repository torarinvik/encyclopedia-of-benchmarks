from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_M = 28
const MAX_INPUT = 97
const MAX_VERTICES = 24

fn put_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("edge_colored_graph_layer_encoding")
fn edge_colored_graph_layer_encoding(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > MAX_INPUT: return -1
    let n0 = input[0]
    let m0 = input[1]
    let d0 = input[2]
    let q0 = input[3]
    if n0 < 1 or n0 > 8 or m0 < 0 or m0 > 28 or d0 < 1 or d0 > 3 or q0 < 1 or q0 > 3: return -1
    let n = Int(n0)
    let m = Int(m0)
    let layers = Int(d0)
    let classes = Int(q0)
    let edge_offset = 4 + n
    if length != c_size_t(edge_offset + 3 * m): return -1
    var vertex_colors = InlineArray[Int64, 8](fill=0)
    for vertex in range(n):
        vertex_colors[vertex] = input[4 + vertex]
        if vertex_colors[vertex] < 0 or vertex_colors[vertex] >= q0: return -1
    var source_edges = InlineArray[UInt8, 64](fill=0)
    for edge in range(m):
        let offset = edge_offset + 3 * edge
        var u0 = input[offset]
        var v0 = input[offset + 1]
        let color = input[offset + 2]
        if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or color < 1 or color >= (1 << d0): return -1
        if u0 > v0:
            let temp = u0
            u0 = v0
            v0 = temp
        let u = Int(u0)
        let v = Int(v0)
        if source_edges[u * MAX_N + v] != 0: return -1
        source_edges[u * MAX_N + v] = UInt8(color)

    let nodes = n * layers
    var adjacency = InlineArray[Bool, 576](fill=False)
    for layer in range(layers):
        for u in range(n):
            for v in range(u + 1, n):
                if source_edges[u * MAX_N + v] & UInt8(1 << layer) != 0:
                    adjacency[(layer * n + u) * MAX_VERTICES + layer * n + v] = True
    for vertex in range(n):
        for layer in range(layers - 1):
            adjacency[(layer * n + vertex) * MAX_VERTICES + (layer + 1) * n + vertex] = True
    var edge_count = 0
    for u in range(nodes):
        for v in range(u + 1, nodes):
            if adjacency[u * MAX_VERTICES + v]: edge_count += 1
    let output_bytes = 8 * (2 + nodes + 2 * edge_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    put_le(output, 0, Int64(nodes))
    put_le(output, 8, Int64(edge_count))
    var word = 2
    for layer in range(layers):
        for vertex in range(n):
            put_le(output, 8 * word, Int64(layer * classes) + vertex_colors[vertex])
            word += 1
    for u in range(nodes):
        for v in range(u + 1, nodes):
            if adjacency[u * MAX_VERTICES + v]:
                put_le(output, 8 * word, Int64(u))
                word += 1
                put_le(output, 8 * word, Int64(v))
                word += 1
    Int64(output_bytes)
