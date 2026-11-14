from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ida_star_graph")
fn ida_star_graph(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    let invalid = Int64(-9223372036854775807) - 1
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 112: return invalid
    let nv = values[0]; let mv = values[1]; let sv = values[2]; let gv = values[3]
    if nv < 1 or nv > 12 or mv < 0 or mv > 48 or sv < 0 or sv >= nv or gv < 0 or gv >= nv: return invalid
    let n = Int(nv); let m = Int(mv); let start = Int(sv); let goal = Int(gv)
    if length != c_size_t(4+n+2*m): return invalid
    var heuristic = InlineArray[Int, 12](fill=0)
    var edges = InlineArray[UInt16, 12](fill=0)
    for i in range(n):
        if values[4+i] < 0 or values[4+i] >= nv: return invalid
        heuristic[i] = Int(values[4+i])
    if heuristic[goal] != 0: return invalid
    for i in range(m):
        let uv = values[4+n+2*i]; let vv = values[5+n+2*i]
        if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv: return invalid
        let u = Int(uv); let v = Int(vv); let bit = UInt16(1) << v
        if (edges[u] & bit) != 0 or heuristic[u] > heuristic[v]+1: return invalid
        edges[u] |= bit
    var bound = heuristic[start]
    while True:
        var next_bound = 1000
        var vertices = InlineArray[Int, 12](fill=0)
        var next_neighbor = InlineArray[Int, 12](fill=0)
        var depth = 0
        var path = UInt16(1) << start
        vertices[0] = start
        while depth >= 0:
            let u = vertices[depth]
            if u == goal: return Int64(depth)
            var v = next_neighbor[depth]
            while v < n and ((edges[u] & (UInt16(1) << v)) == 0 or (path & (UInt16(1) << v)) != 0):
                v += 1
            if v == n:
                path &= ~(UInt16(1) << u)
                depth -= 1
                continue
            next_neighbor[depth] = v+1
            let score = depth+1+heuristic[v]
            if score > bound:
                next_bound = min(next_bound, score)
            else:
                depth += 1
                vertices[depth] = v
                next_neighbor[depth] = 0
                path |= UInt16(1) << v
        if next_bound == 1000: return -1
        bound = next_bound
