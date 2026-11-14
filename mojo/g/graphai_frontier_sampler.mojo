# Independent bounded GraphAIBench sampling profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("graphai_frontier_sampler")
fn graphai_frontier_sampler(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 3 or length > 124: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let nv = input[0]
    let mv = input[1]
    let rv = input[2]
    if nv < 1.0 or nv > 8.0 or mv < 0.0 or mv > 24.0 or rv < 1.0 or rv > 4.0: return -1
    let n = Int(nv)
    let m = Int(mv)
    let roots = Int(rv)
    if Float64(n) != nv or Float64(m) != mv or Float64(roots) != rv or length != c_size_t(4+n+m+22*roots): return -1
    let row_at = 3+roots
    let col_at = row_at+n+1
    let choice_at = col_at+m
    var frontier = List[Int](capacity=48)
    var staged = List[Float64](capacity=88)
    var rows = List[Int](capacity=n+1)
    var cols = List[Int](capacity=m)
    for i in range(roots):
        let value = input[3+i]
        if value < 0.0 or value >= nv or Float64(Int(value)) != value: return -1
        frontier.append(Int(value))
        staged.append(value)
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
    var choice = 0
    for round in range(3):
        var fanout = 2
        if round == 0: fanout = 3
        var following = List[Int](capacity=len(frontier)*fanout)
        for i in range(len(frontier)):
            let parent = frontier[i]
            let begin = rows[parent]
            let degree = rows[parent+1]-begin
            if degree == 0: return -1
            for _ in range(fanout):
                let draw = input[choice_at+choice]
                choice += 1
                if draw < 0.0 or draw >= Float64(degree) or Float64(Int(draw)) != draw: return -1
                let vertex = cols[begin+Int(draw)]
                following.append(vertex)
                staged.append(Float64(vertex))
        frontier = following^
    let required = 22*roots
    if choice != 21*roots or len(staged) != required: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(required): output[i] = staged[i]
    return Int64(required)
