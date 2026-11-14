from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("olden_em3d")
fn olden_em3d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]; let dv = input[1]
    if not (nv >= 1.0 and nv <= 8.0 and dv >= 1.0 and dv <= 4.0): return -1
    let n = Int(nv); let degree = Int(dv)
    if Float64(n) != nv or Float64(degree) != dv: return -1
    let edges = n*degree
    if length != c_size_t(2+2*n+4*edges): return -1
    var electric = List[Float64](capacity=n)
    var magnetic = List[Float64](capacity=n)
    for i in range(n):
        let e = input[2+i]; let h = input[2+n+i]
        if not (e >= 0.0 and e <= 1.0 and h >= 0.0 and h <= 1.0): return -1
        electric.append(e); magnetic.append(h)
    let en = 2+2*n
    let ec = en+edges
    let hn = ec+edges
    let hc = hn+edges
    for i in range(edges):
        let a = input[en+i]; let b = input[hn+i]
        let ca = input[ec+i]; let cb = input[hc+i]
        if not (a >= 0.0 and a < nv and b >= 0.0 and b < nv and ca >= 0.0 and ca <= 1.0 and cb >= 0.0 and cb <= 1.0): return -1
        if Float64(Int(a)) != a or Float64(Int(b)) != b: return -1
        let start = (i//degree)*degree
        for j in range(start,i):
            if input[en+j] == a or input[hn+j] == b: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(2*n): return -2
    for node in range(n):
        var current = electric[node]
        let base = node*degree
        for edge in range(degree):
            let neighbor = Int(input[en+base+edge])
            current -= input[ec+base+(edge & ~1)]*magnetic[neighbor]
        electric[node] = current
    for node in range(n):
        var current = magnetic[node]
        let base = node*degree
        for edge in range(degree):
            let neighbor = Int(input[hn+base+edge])
            current -= input[hc+base+(edge & ~1)]*electric[neighbor]
        magnetic[node] = current
    for i in range(n): output[i] = electric[i]; output[n+i] = magnetic[i]
    return Int64(2*n)
