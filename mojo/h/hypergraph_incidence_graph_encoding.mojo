from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_M = 12
const MAX_INPUT = 111

fn put_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("hypergraph_incidence_graph_encoding")
fn hypergraph_incidence_graph_encoding(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 8 or m64 < 0 or m64 > 12: return -1
    let n = Int(n64)
    let m = Int(m64)
    var incidence = InlineArray[Bool, 96](fill=False)
    var offset = 2
    for edge in range(m):
        if c_size_t(offset) >= length: return -1
        let size64 = input[offset]
        offset += 1
        if size64 < 0 or size64 > n64 or c_size_t(size64) > length - c_size_t(offset): return -1
        for _ in range(Int(size64)):
            let vertex64 = input[offset]
            offset += 1
            if vertex64 < 0 or vertex64 >= n64: return -1
            let vertex = Int(vertex64)
            if incidence[vertex * MAX_M + edge]: return -1
            incidence[vertex * MAX_M + edge] = True
    if c_size_t(offset) != length: return -1

    var count = 0
    for vertex in range(n):
        for edge in range(m):
            if incidence[vertex * MAX_M + edge]: count += 1
    let nodes = n + m
    let bytes = 8 * (2 + nodes + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_le(output, 0, Int64(nodes))
    put_le(output, 8, Int64(count))
    var word = 2
    for _ in range(n):
        put_le(output, 8 * word, 0)
        word += 1
    for _ in range(m):
        put_le(output, 8 * word, 1)
        word += 1
    for vertex in range(n):
        for edge in range(m):
            if incidence[vertex * MAX_M + edge]:
                put_le(output, 8 * word, Int64(vertex))
                word += 1
                put_le(output, 8 * word, Int64(n + edge))
                word += 1
    return Int64(bytes)
