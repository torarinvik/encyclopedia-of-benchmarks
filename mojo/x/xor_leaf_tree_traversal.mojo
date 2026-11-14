from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("xor_leaf_tree_traversal")
fn xor_leaf_tree_traversal(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    if input[1] < 0 or input[1] >= Int64(n) or Int(length) != 2 * n: return -1
    let root = Int(input[1])
    var degree = InlineArray[Int, 64](fill=0)
    var edge_xor = InlineArray[Int, 64](fill=0)
    var parents = InlineArray[Int, 64](fill=-1)
    var dsu = InlineArray[Int, 64](fill=0)
    var ranks = InlineArray[Int, 64](fill=0)
    var order = InlineArray[Int, 64](fill=0)
    var a = InlineArray[Int, 63](fill=0)
    var b = InlineArray[Int, 63](fill=0)
    for i in range(n): dsu[i] = i
    for e in range(n - 1):
        let u0 = input[2 + 2 * e]
        let v0 = input[3 + 2 * e]
        if u0 < 0 or u0 >= Int64(n) or v0 < 0 or v0 >= Int64(n) or u0 == v0: return -1
        let u = Int(u0)
        let v = Int(v0)
        var x = u
        var y = v
        while dsu[x] != x:
            dsu[x] = dsu[dsu[x]]
            x = dsu[x]
        while dsu[y] != y:
            dsu[y] = dsu[dsu[y]]
            y = dsu[y]
        if x == y: return -1
        if ranks[x] < ranks[y]:
            dsu[x] = y
        else:
            dsu[y] = x
            if ranks[x] == ranks[y]: ranks[x] += 1
        a[e] = u
        b[e] = v
        degree[u] += 1
        degree[v] += 1
        edge_xor[u] = edge_xor[u] ^ e
        edge_xor[v] = edge_xor[v] ^ e
    degree[root] = 0
    var used = 0
    for start in range(n):
        var v = start
        while degree[v] == 1:
            let e = edge_xor[v]
            let next = a[e] ^ b[e] ^ v
            parents[v] = e
            order[used] = v
            used += 1
            degree[v] = 0
            degree[next] -= 1
            edge_xor[next] = edge_xor[next] ^ e
            v = next
    order[used] = root
    used += 1
    if used != n: return -1
    let bytes = 16 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(2 * n):
        var value: Int64 = 0
        if i < n: value = Int64(parents[i])
        else: value = Int64(order[i - n])
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
