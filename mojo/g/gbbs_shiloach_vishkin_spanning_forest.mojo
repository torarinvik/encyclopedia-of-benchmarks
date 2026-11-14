# Independent bounded GBBS spanning-forest profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn root(parent: List[Int], vertex: Int) -> Int:
    var u = vertex
    while parent[u] != u: u = parent[u]
    return u

@export("gbbs_shiloach_vishkin_spanning_forest")
fn gbbs_shiloach_vishkin_spanning_forest(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 50: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 12 or mv < 0 or mv > 24 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var seen = List[Int](capacity=n)
    var us = List[Int](capacity=m)
    var vs = List[Int](capacity=m)
    var selected = List[UInt8](capacity=m)
    for _ in range(n): seen.append(0)
    for e in range(m):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (seen[a] & (1 << b)) != 0: return -1
        seen[a] |= 1 << b
        us.append(a)
        vs.append(b)
        selected.append(0)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(m): return -2
    var parent = List[Int](capacity=n)
    var previous = List[Int](capacity=n)
    var next = List[Int](capacity=n)
    var best = List[Int](capacity=n)
    for u in range(n):
        parent.append(u)
        previous.append(u)
        next.append(u)
        best.append(n)
    for _ in range(n):
        for u in range(n):
            previous[u] = root(parent,u)
            next[u] = previous[u]
            best[u] = n
        for e in range(m):
            let a = previous[us[e]]
            let b = previous[vs[e]]
            if a == b: continue
            var low = a
            var high = b
            if a > b:
                low = b
                high = a
            if low < best[high]: best[high] = low
        var changed = False
        for high in range(n):
            let low = best[high]
            if low == n: continue
            next[high] = low
            changed = True
            for e in range(m):
                let a = previous[us[e]]
                let b = previous[vs[e]]
                if (a == high and b == low) or (a == low and b == high):
                    selected[e] = 1
                    break
        for u in range(n): parent[u] = root(next,u)
        if not changed: break
    for e in range(m): output[e] = selected[e]
    return Int64(m)
