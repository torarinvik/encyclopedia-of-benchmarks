# Independent bounded GAPBS PageRank profile; see package BSD notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gapbs_pagerank_pull_gs")
fn gapbs_pagerank_pull_gs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 66: return -1
    let nv = input[0]
    let iterations = input[1]
    if nv < 2 or nv > 8 or iterations < 0 or iterations > 20 or length != c_size_t(2+nv*nv): return -1
    let n = Int(nv)
    var matrix = List[Int](capacity=n*n)
    var degree = List[Int](capacity=n)
    for u in range(n):
        var count = 0
        for v in range(n):
            let edge = input[2+u*n+v]
            if (edge != 0 and edge != 1) or (u == v and edge != 0): return -1
            matrix.append(Int(edge))
            count += Int(edge)
        if count == 0: return -1
        degree.append(count)
    let damping = Float32(0.85)
    let initial = Float32(1.0)/Float32(n)
    let base = Float32(Float32(1.0)-damping)/Float32(n)
    var scores = List[Float32](capacity=n)
    var outgoing = List[Float32](capacity=n)
    for u in range(n):
        scores.append(initial)
        outgoing.append(Float32(initial/Float32(degree[u])))
    for _ in range(Int(iterations)):
        for target in range(n):
            var incoming = Float32(0.0)
            for source in range(n):
                if matrix[source*n+target] != 0: incoming = Float32(incoming+outgoing[source])
            let product = Float32(damping*incoming)
            scores[target] = Float32(base+product)
            outgoing[target] = Float32(scores[target]/Float32(degree[target]))
    var weighted = Float64(0.0)
    for u in range(n): weighted += Float64(u+1)*Float64(scores[u])
    return Int64(weighted*100.0+0.5)
