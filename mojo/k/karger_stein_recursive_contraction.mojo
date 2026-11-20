# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ks_root(parent: InlineArray[Int, 12], vertex: Int) -> Int:
    var current = vertex
    while parent[current] != current: current = parent[current]
    return current

fn ks_solve(left: InlineArray[Int, 32], right: InlineArray[Int, 32], n: Int, m: Int,
            tape: InlineArray[Int64, 64], q: Int, inout position: Int,
            parent: InlineArray[Int, 12], components: Int) -> Int64:
    if components <= 6:
        var index = InlineArray[Int, 12](fill=0)
        var count = 0
        for i in range(n):
            if parent[i] == i:
                index[i] = count
                count += 1
        var best = Int64(m+1)
        for mask in range((1 << (components-1))-1):
            let side = (mask << 1) | 1
            var cut: Int64 = 0
            for e in range(m):
                let a = index[ks_root(parent, left[e])]
                let b = index[ks_root(parent, right[e])]
                if ((side >> a) & 1) != ((side >> b) & 1): cut += 1
            if cut < best: best = cut
        return best
    var targets = InlineArray[Int, 13](fill=0)
    targets[7] = 6; targets[8] = 7; targets[9] = 8
    targets[10] = 9; targets[11] = 9; targets[12] = 10
    let target = targets[components]
    var best = Int64(m+1)
    for branch in range(2):
        var next = InlineArray[Int, 12](fill=0)
        for i in range(n): next[i] = parent[i]
        var remaining = components
        while remaining > target:
            var live: Int64 = 0
            for e in range(m):
                if ks_root(next, left[e]) != ks_root(next, right[e]): live += 1
            if position >= q: return -1
            var rank = tape[position]
            position += 1
            if rank < 0 or rank >= live: return -1
            for e in range(m):
                let a = ks_root(next, left[e])
                let b = ks_root(next, right[e])
                if a == b: continue
                if rank == 0:
                    next[b] = a
                    break
                rank -= 1
            remaining -= 1
        let value = ks_solve(left, right, n, m, tape, q, position, next, target)
        if value < 0: return -1
        if value < best: best = value
    return best

@export("karger_stein_recursive_contraction")
fn karger_stein_recursive_contraction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 132: return -1
    if input[0] < 2 or input[0] > 12 or input[1] < 1 or input[1] > 32 or input[2] < 0 or input[2] > 64: return -1
    let n = Int(input[0]); let m = Int(input[1]); let q = Int(input[2])
    if length != c_size_t(3+2*m+q): return -1
    var left = InlineArray[Int, 32](fill=0)
    var right = InlineArray[Int, 32](fill=0)
    var tape = InlineArray[Int64, 64](fill=0)
    var parent = InlineArray[Int, 12](fill=0)
    for i in range(n): parent[i] = i
    for i in range(m):
        let u = input[3+2*i]; let v = input[4+2*i]
        if u < 0 or v < 0 or u >= Int64(n) or v >= Int64(n) or u == v: return -1
        left[i] = Int(u); right[i] = Int(v)
        let a = ks_root(parent, left[i]); let b = ks_root(parent, right[i])
        parent[b] = a
    let initial = ks_root(parent, 0)
    for i in range(1,n):
        if ks_root(parent, i) != initial: return -1
    for i in range(n): parent[i] = i
    for i in range(q): tape[i] = input[3+2*m+i]
    var position = 0
    let value = ks_solve(left, right, n, m, tape, q, position, parent, n)
    if value < 0 or position != q: return -1
    return value
