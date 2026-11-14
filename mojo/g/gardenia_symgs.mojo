# Independent bounded GARDENIA SymGS profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gardenia_symgs")
fn gardenia_symgs(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 3 or length > 173: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let nv = input[0]
    let mv = input[1]
    let cv = input[2]
    if nv < 1.0 or nv > 8.0 or mv < 1.0 or mv > 64.0 or cv < 1.0 or cv > nv: return -1
    let n = Int(nv)
    let m = Int(mv)
    let colors = Int(cv)
    if Float64(n) != nv or Float64(m) != mv or Float64(colors) != cv: return -1
    if length != c_size_t(5+4*n+colors+2*m): return -1
    let oa = 3
    let fa = oa+n
    let ra = fa+colors+1
    let ca = ra+n+1
    let va = ca+m
    let xa = va+m
    let ba = xa+n
    var order = List[Int](capacity=n)
    var offsets = List[Int](capacity=colors+1)
    var rows = List[Int](capacity=n+1)
    var cols = List[Int](capacity=m)
    var matrix = List[Float64](capacity=m)
    var group = List[Int](capacity=n)
    var seen = List[Bool](capacity=n)
    var x = List[Float64](capacity=n)
    for _ in range(n):
        group.append(0)
        seen.append(False)
    for i in range(n):
        let v = input[oa+i]
        if v < 0.0 or v >= nv: return -1
        let u = Int(v)
        if Float64(u) != v or seen[u]: return -1
        order.append(u)
        seen[u] = True
    for i in range(colors+1):
        let v = input[fa+i]
        if v < 0.0 or v > nv or Float64(Int(v)) != v: return -1
        offsets.append(Int(v))
    if offsets[0] != 0 or offsets[colors] != n: return -1
    for k in range(colors):
        if offsets[k] >= offsets[k+1]: return -1
        for p in range(offsets[k],offsets[k+1]): group[order[p]] = k
    for i in range(n+1):
        let v = input[ra+i]
        if v < 0.0 or v > mv or Float64(Int(v)) != v: return -1
        let r = Int(v)
        if i > 0 and r < rows[i-1]: return -1
        rows.append(r)
    if rows[0] != 0 or rows[n] != m: return -1
    for e in range(m):
        let v = input[ca+e]
        let value = input[va+e]
        if v < 0.0 or v >= nv or Float64(Int(v)) != v or value < -4.0 or value > 4.0: return -1
        cols.append(Int(v))
        matrix.append(value)
    for u in range(n):
        var diagonal = Float64(0.0)
        var offsum = Float64(0.0)
        var found_diag = False
        var previous = -1
        for e in range(rows[u],rows[u+1]):
            let v = cols[e]
            if v <= previous: return -1
            previous = v
            if v == u:
                diagonal = matrix[e]
                found_diag = True
            else:
                if group[u] == group[v]: return -1
                if matrix[e] < 0.0: offsum -= matrix[e]
                else: offsum += matrix[e]
            var found = False
            for f in range(rows[v],rows[v+1]):
                if cols[f] == u:
                    if matrix[f] != matrix[e]: return -1
                    found = True
                    break
            if not found: return -1
        if not found_diag or diagonal <= offsum: return -1
    for i in range(n):
        if input[xa+i] < -4.0 or input[xa+i] > 4.0 or input[ba+i] < -4.0 or input[ba+i] > 4.0: return -1
        x.append(input[xa+i])
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for pass_index in range(2):
        for step in range(colors):
            var k = step
            if pass_index == 1: k = colors-1-step
            for p in range(offsets[k],offsets[k+1]):
                let u = order[p]
                var sum = Float64(0.0)
                var diagonal = Float64(0.0)
                for e in range(rows[u],rows[u+1]):
                    let v = cols[e]
                    if v == u: diagonal = matrix[e]
                    else: sum += x[v]*matrix[e]
                x[u] = (input[ba+u]-sum)/diagonal
    for i in range(n): output[i] = x[i]
    return Int64(n)
