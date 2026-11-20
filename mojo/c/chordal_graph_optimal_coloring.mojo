# Uncompiled chordal-graph optimal coloring draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("chordal_graph_optimal_coloring")
fn chordal_graph_optimal_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 18: return -1
    let nv = input[0]
    if nv < 1 or nv > 16 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    var rows = InlineArray[Int,16](fill=0)
    var weight = InlineArray[Int,16](fill=0)
    var colors = InlineArray[Int,16](fill=-1)
    var order = InlineArray[Int,16](fill=0)
    for v in range(n):
        if input[v+1] < 0 or input[v+1] >= Int64(1 << n) or (input[v+1] & Int64(1 << v)) != 0: return -1
        rows[v] = Int(input[v+1])
    for v in range(n):
        for u in range(v):
            if ((rows[v] >> u) & 1) != ((rows[u] >> v) & 1): return -1
    var selected = 0
    for i in range(n):
        var vertex = -1
        for u in range(n):
            if (selected & (1 << u)) == 0:
                if vertex < 0: vertex = u
                elif weight[u] > weight[vertex]: vertex = u
        let earlier = rows[vertex] & selected
        for j in range(i):
            let u = order[j]
            if (earlier & (1 << u)) != 0 and (earlier & ~(rows[u] | (1 << u))) != 0: return -2
        order[i] = vertex
        selected |= 1 << vertex
        for u in range(n):
            if (selected & (1 << u)) == 0 and (rows[vertex] & (1 << u)) != 0: weight[u] += 1
    var maximum = 0
    for i in range(n):
        let v = order[i]
        var used = 0
        for u in range(n):
            if (rows[v] & (1 << u)) != 0 and colors[u] >= 0: used |= 1 << colors[u]
        var color = 0
        while (used & (1 << color)) != 0: color += 1
        colors[v] = color
        if color+1 > maximum: maximum = color+1
    return Int64(maximum)
