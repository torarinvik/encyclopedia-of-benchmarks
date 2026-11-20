from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("nagamochi_ibaraki_sparse_k_connectivity_certificate")
fn nagamochi_ibaraki_sparse_k_connectivity_certificate(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 60: return -1
    let n64 = input[0]
    let m64 = input[1]
    let k64 = input[2]
    if n64 < 3 or n64 > 8 or m64 < 0 or m64 > 28 or k64 < 1 or k64 > 3: return -1
    let n = Int(n64)
    let m = Int(m64)
    let k = Int(k64)
    if length != c_size_t(3 + 2 * m): return -1

    var u = InlineArray[Int, 28](fill=0)
    var v = InlineArray[Int, 28](fill=0)
    var incident = InlineArray[Int, 64](fill=0)
    var degree = InlineArray[Int, 8](fill=0)
    for e in range(m):
        let a64 = input[3 + 2 * e]
        let b64 = input[4 + 2 * e]
        if a64 < 0 or a64 >= b64 or b64 >= n64: return -1
        let a = Int(a64)
        let b = Int(b64)
        for prior in range(e):
            if u[prior] == a and v[prior] == b: return -1
        u[e] = a
        v[e] = b
        incident[a * 8 + degree[a]] = e
        degree[a] += 1
        incident[b * 8 + degree[b]] = e
        degree[b] += 1

    let bytes = 8 * (m + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var rank = InlineArray[Int, 8](fill=0)
    var layer = InlineArray[Int, 28](fill=0)
    var scanned_vertex = InlineArray[Bool, 8](fill=False)
    var scanned_edge = InlineArray[Bool, 28](fill=False)
    for _ in range(n):
        var x = n
        for vertex in range(n):
            if not scanned_vertex[vertex] and (x == n or rank[vertex] > rank[x]): x = vertex
        for slot in range(degree[x]):
            let e = incident[x * 8 + slot]
            if scanned_edge[e]: continue
            let y = u[e] == x ? v[e] : u[e]
            layer[e] = rank[y] + 1
            if rank[x] == rank[y]: rank[x] += 1
            rank[y] += 1
            scanned_edge[e] = True
        scanned_vertex[x] = True

    store_i64(output, 0, Int64(m))
    for e in range(m):
        var visible = layer[e]
        if visible > k: visible = 0
        store_i64(output, 8 * (e + 1), Int64(visible))
    return Int64(bytes)
