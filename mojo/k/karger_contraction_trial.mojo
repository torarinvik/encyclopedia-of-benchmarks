from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn root(parent: InlineArray[Int, 8], vertex: Int) -> Int:
    var current = vertex
    while parent[current] != current:
        current = parent[current]
    return current

@export("karger_contraction_trial")
fn karger_contraction_trial(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 57:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 2 or n64 > 8 or m64 < 1 or m64 > 24:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m + n - 2):
        return -1
    var u = InlineArray[Int, 24](fill=0)
    var v = InlineArray[Int, 24](fill=0)
    var parent = InlineArray[Int, 8](fill=0)
    for i in range(n):
        parent[i] = i
    for i in range(m):
        let a = input[2 + 2 * i]
        let b = input[3 + 2 * i]
        if a < 0 or b < 0 or a >= n64 or b >= n64 or a == b:
            return -1
        u[i] = Int(a)
        v[i] = Int(b)
        let left = root(parent, u[i])
        let right = root(parent, v[i])
        parent[left] = right
    let initial = root(parent, 0)
    for i in range(1, n):
        if root(parent, i) != initial:
            return -1
    for i in range(n):
        parent[i] = i
    for step in range(n - 2):
        var live: Int64 = 0
        for i in range(m):
            if root(parent, u[i]) != root(parent, v[i]):
                live += 1
        var rank = input[2 + 2 * m + step]
        if rank < 0 or rank >= live:
            return -1
        for i in range(m):
            let left = root(parent, u[i])
            let right = root(parent, v[i])
            if left == right:
                continue
            if rank == 0:
                parent[left] = right
                break
            rank -= 1
    var cut: Int64 = 0
    for i in range(m):
        if root(parent, u[i]) != root(parent, v[i]):
            cut += 1
    return cut
