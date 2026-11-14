# Independent bounded GraphAIBench GCN aggregation; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("graphai_gcn_aggregation")
fn graphai_gcn_aggregation(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 7 or length > 84: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let nv = input[0]
    let mv = input[1]
    let dv = input[2]
    if nv < 1.0 or nv > 8.0 or mv < 0.0 or mv > 24.0 or dv < 1.0 or dv > 4.0: return -1
    let n = Int(nv)
    let m = Int(mv)
    let d = Int(dv)
    if Float64(n) != nv or Float64(m) != mv or Float64(d) != dv or length != c_size_t(4+3*n+m+n*d): return -1
    let row_at = 3
    let col_at = row_at+n+1
    let left_at = col_at+m
    let right_at = left_at+n
    let feature_at = right_at+n
    var rows = List[Int](capacity=n+1)
    var cols = List[Int](capacity=m)
    for i in range(n+1):
        let value = input[row_at+i]
        if value < 0.0 or value > mv or Float64(Int(value)) != value: return -1
        let r = Int(value)
        if i > 0 and r < rows[i-1]: return -1
        rows.append(r)
    if rows[0] != 0 or rows[n] != m: return -1
    for e in range(m):
        let value = input[col_at+e]
        if value < 0.0 or value >= nv or Float64(Int(value)) != value: return -1
        cols.append(Int(value))
    for i in range(n):
        if input[left_at+i] < -4.0 or input[left_at+i] > 4.0 or input[right_at+i] < -4.0 or input[right_at+i] > 4.0: return -1
    for i in range(n*d):
        if input[feature_at+i] < -8.0 or input[feature_at+i] > 8.0: return -1
    let required = n*d
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var staged = List[Float64](capacity=required)
    for _ in range(required): staged.append(0.0)
    for u in range(n):
        for e in range(rows[u],rows[u+1]):
            let v = cols[e]
            let weight = input[left_at+u]*input[right_at+v]
            for k in range(d): staged[u*d+k] += weight*input[feature_at+v*d+k]
    for i in range(required): output[i] = staged[i]
    return Int64(required)
