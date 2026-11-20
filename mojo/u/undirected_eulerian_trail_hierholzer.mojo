from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("undirected_eulerian_trail_hierholzer")
fn undirected_eulerian_trail_hierholzer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 67: return -1
    let n0 = input[0]
    let m0 = input[1]
    if n0 < 1 or n0 > 16 or m0 < 0 or m0 > 32 or length != c_size_t(2 + 2 * m0): return -1
    let n = Int(n0)
    let m = Int(m0)
    var endpoints = List[Int](length=64, fill=0)
    var adjacency = List[Int](length=1024, fill=0)
    var degree = List[Int](length=16, fill=0)
    var cursor = List[Int](length=16, fill=0)
    for e in range(m):
        let u0 = input[2 + 2 * e]
        let v0 = input[3 + 2 * e]
        if u0 < 0 or v0 < 0 or u0 >= n0 or v0 >= n0: return -1
        let u = Int(u0)
        let v = Int(v0)
        endpoints[2 * e] = u
        endpoints[2 * e + 1] = v
        adjacency[64 * u + degree[u]] = e
        degree[u] += 1
        adjacency[64 * v + degree[v]] = e
        degree[v] += 1
    var odd = 0
    var start = 0
    for v in range(n):
        if degree[v] % 2 != 0:
            if odd == 0: start = v
            odd += 1
    if odd != 0 and odd != 2: return 0
    if odd == 0 and m != 0:
        while degree[start] == 0: start += 1
    var used = List[Bool](length=32, fill=False)
    var stack = List[Int](length=33, fill=0)
    var reverse = List[Int](length=33, fill=0)
    var top = 1
    var count = 0
    stack[0] = start
    while top != 0:
        let v = stack[top - 1]
        while cursor[v] < degree[v] and used[adjacency[64 * v + cursor[v]]]: cursor[v] += 1
        if cursor[v] == degree[v]:
            top -= 1
            reverse[count] = stack[top]
            count += 1
        else:
            let e = adjacency[64 * v + cursor[v]]
            cursor[v] += 1
            used[e] = True
            var next = endpoints[2 * e]
            if next == v: next = endpoints[2 * e + 1]
            stack[top] = next
            top += 1
    if count != m + 1: return 0
    let bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(count):
        var value = UInt64(reverse[count - 1 - i])
        for b in range(8):
            output[8 * i + b] = UInt8(value & 255)
            value >>= 8
    return Int64(bytes)
