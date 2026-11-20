from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_M = 20

fn secret_find(mut parent: InlineArray[Int, MAX_N], node_input: Int) -> Int:
    var node = node_input
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn secret_join(mut parent: InlineArray[Int, MAX_N], mut sizes: InlineArray[Int, MAX_N],
               left: Int, right: Int):
    var a = secret_find(mut parent, left)
    var b = secret_find(mut parent, right)
    if a == b: return
    if sizes[a] < sizes[b]:
        let swap = a
        a = b
        b = swap
    parent[b] = a
    sizes[a] += sizes[b]

@export("secret_sharing_time_batched_dsu")
fn secret_sharing_time_batched_dsu(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 64: return -1
    let n_value = input[0]
    let first_value = input[1]
    let m_value = input[2]
    if n_value < 2 or n_value > MAX_N or first_value < 1 or first_value >= n_value
        or m_value < 0 or m_value > MAX_M: return -1
    let n = Int(n_value)
    let first = Int(first_value)
    let m = Int(m_value)
    if Int(length) != 3 + 3 * m: return -1
    for i in range(m):
        let u = input[3 + 3 * i]
        let v = input[4 + 3 * i]
        let time = input[5 + 3 * i]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or u == v or time < 1 or time > 20:
            return -1

    var parent = InlineArray[Int, MAX_N](fill=0)
    var sizes = InlineArray[Int, MAX_N](fill=1)
    for node in range(n): parent[node] = node
    secret_join(mut parent, mut sizes, 0, first)
    for time in range(1, 21):
        var touched = InlineArray[Bool, MAX_N](fill=False)
        for i in range(m):
            let u = Int(input[3 + 3 * i])
            let v = Int(input[4 + 3 * i])
            if input[5 + 3 * i] == Int64(time):
                secret_join(mut parent, mut sizes, u, v)
                touched[u] = True
                touched[v] = True
        let known_root = secret_find(mut parent, 0)
        for node in range(n):
            if touched[node] and secret_find(mut parent, node) != known_root:
                parent[node] = node
                sizes[node] = 1
    let known_root = secret_find(mut parent, 0)
    var result: Int64 = 0
    for node in range(n):
        if secret_find(mut parent, node) == known_root:
            result |= Int64(1) << node
    return result
