# Independent bounded GraphAIBench attention aggregation; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import exp, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("graphai_gat_aggregation")
fn graphai_gat_aggregation(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 3 or length > 76: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let nv = input[0]
    let mv = input[1]
    let dv = input[2]
    if nv < 1.0 or nv > 8.0 or mv < 0.0 or mv > 24.0 or dv < 1.0 or dv > 4.0: return -1
    let n = Int(nv)
    let m = Int(mv)
    let d = Int(dv)
    if Float64(n) != nv or Float64(m) != mv or Float64(d) != dv or length != c_size_t(4+n+m+2*d+n*d): return -1
    let row_at = 3
    let col_at = row_at+n+1
    let left_at = col_at+m
    let right_at = left_at+d
    let feature_at = right_at+d
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
    for i in range(left_at,Int(length)):
        if input[i] < -8.0 or input[i] > 8.0: return -1
    let required = n*d
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var staged = List[Float64](capacity=required)
    var scores = List[Float64](capacity=m)
    var weights = List[Float64](capacity=m)
    for _ in range(required): staged.append(0.0)
    for _ in range(m):
        scores.append(0.0)
        weights.append(0.0)
    for u in range(n):
        let begin = rows[u]
        let end = rows[u+1]
        if begin == end: continue
        var maximum = Float64(-1.0e300)
        for e in range(begin,end):
            let v = cols[e]
            var score = Float64(0.0)
            for k in range(d): score += input[left_at+k]*input[feature_at+u*d+k]
            for k in range(d): score += input[right_at+k]*input[feature_at+v*d+k]
            if score <= 0.0: score *= 0.2
            scores[e] = score
            if score > maximum: maximum = score
        var total = Float64(0.0)
        for e in range(begin,end):
            weights[e] = exp(scores[e]-maximum)
            total += weights[e]
        for e in range(begin,end):
            let v = cols[e]
            let scale = weights[e]/total
            for k in range(d): staged[u*d+k] += scale*input[feature_at+v*d+k]
    for i in range(required): output[i] = staged[i]
    return Int64(required)
