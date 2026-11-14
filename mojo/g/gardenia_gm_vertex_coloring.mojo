# Independent bounded GARDENIA worklist coloring; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gardenia_gm_vertex_coloring")
fn gardenia_gm_vertex_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var colors = List[Int](capacity=n)
    var prior = List[Int](capacity=n)
    var pending = List[Bool](capacity=n)
    var next_pending = List[Bool](capacity=n)
    for _ in range(n):
        rows.append(0)
        colors.append(128)
        prior.append(128)
        pending.append(True)
        next_pending.append(False)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var pending_count = n
    var rounds = 0
    while pending_count > 0:
        rounds += 1
        if rounds > n+1: return -1
        for u in range(n): prior[u] = colors[u]
        for u in range(n):
            if not pending[u]: continue
            var forbidden = 0
            for v in range(n):
                if (rows[u] & (1 << v)) != 0 and prior[v] != 128:
                    forbidden |= 1 << prior[v]
            var color = 0
            while (forbidden & (1 << color)) != 0: color += 1
            colors[u] = color
        pending_count = 0
        for u in range(n):
            next_pending[u] = False
            if not pending[u]: continue
            for v in range(u+1,n):
                if (rows[u] & (1 << v)) != 0 and colors[u] == colors[v]:
                    next_pending[u] = True
                    break
            if next_pending[u]:
                colors[u] = 128
                pending_count += 1
        for u in range(n): pending[u] = next_pending[u]
    for u in range(n):
        let value = Int64(colors[u])
        for byte in range(8): output[8*u+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
