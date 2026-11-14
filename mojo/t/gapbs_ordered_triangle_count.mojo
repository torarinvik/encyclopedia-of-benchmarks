# Independent bounded GAPBS ordered-count profile; see package BSD notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gapbs_ordered_triangle_count")
fn gapbs_ordered_triangle_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257: return -1
    let nv = input[0]
    if nv < 1 or nv > 16 or length != c_size_t(1+nv*nv): return -1
    let n = Int(nv)
    var neighbors = List[Int](capacity=n*n)
    var degree = List[Int](capacity=n)
    for _ in range(n*n): neighbors.append(0)
    for _ in range(n): degree.append(0)
    for u in range(n):
        for v in range(n):
            let edge = input[1+u*n+v]
            if (edge != 0 and edge != 1) or (u == v and edge != 0): return -1
            if edge != input[1+v*n+u]: return -1
            if edge == 1:
                neighbors[u*n+degree[u]] = v
                degree[u] += 1
    var total = Int64(0)
    for u in range(n):
        for vi in range(degree[u]):
            let v = neighbors[u*n+vi]
            if v > u: break
            var edge_pos = 0
            for wi in range(degree[u]):
                let w = neighbors[u*n+wi]
                if w > v: break
                while edge_pos < degree[v] and neighbors[v*n+edge_pos] < w: edge_pos += 1
                if edge_pos < degree[v] and neighbors[v*n+edge_pos] == w: total += 1
    return total
