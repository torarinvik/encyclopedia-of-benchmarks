# Efficient domination via weighted independent set on the square graph.
from std.ffi import c_size_t
from std.collections import InlineArray
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("efficient_dominating_set_square_graph_mwis")
fn efficient_dominating_set_square_graph_mwis(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                               length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 135: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 12 or m64 < 0 or m64 > n64 * (n64 - 1) // 2: return -1
    if length != c_size_t(2 + 2 * m64): return -1
    let n = Int(n64)
    let m = Int(m64)
    var adjacency = InlineArray[UInt64, 12](fill=0)
    for e in range(m):
        let u64 = input[2 + 2*e]
        let v64 = input[3 + 2*e]
        if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
        let u = Int(u64)
        let v = Int(v64)
        let bit = UInt64(1) << v
        if (adjacency[u] & bit) != 0: return -1
        adjacency[u] |= bit
        adjacency[v] |= UInt64(1) << u

    var square = InlineArray[UInt64, 12](fill=0)
    var weights = InlineArray[Int, 12](fill=0)
    for v in range(n):
        square[v] = adjacency[v]
        for u in range(n):
            if (adjacency[v] & (UInt64(1) << u)) != 0: square[v] |= adjacency[u]
        square[v] &= ~(UInt64(1) << v)
        var degree = 0
        var bits = adjacency[v]
        while bits != 0:
            bits &= bits - 1
            degree += 1
        weights[v] = degree + 1
    let answer = weighted_mis(square, weights, n, (UInt64(1) << n) - 1, 0)
    if answer == Int(n64): return 1
    return 0

fn weighted_mis(square: InlineArray[UInt64, 12], weights: InlineArray[Int, 12],
                n: Int, remaining: UInt64, current: Int) -> Int:
    if remaining == 0: return current
    var branch = -1
    var branch_degree = -1
    for v in range(n):
        let bit = UInt64(1) << v
        if (remaining & bit) == 0: continue
        var degree = 0
        var bits = square[v] & remaining
        while bits != 0:
            bits &= bits - 1
            degree += 1
        if degree > branch_degree:
            branch = v
            branch_degree = degree
    let bit = UInt64(1) << branch
    let include_remaining = remaining & ~bit & ~square[branch]
    let with_branch = weighted_mis(square, weights, n, include_remaining, current + weights[branch])
    let exclude_remaining = remaining & ~bit
    var exclusion_upper = current
    for v in range(n):
        if (exclude_remaining & (UInt64(1) << v)) != 0: exclusion_upper += weights[v]
    if exclusion_upper <= with_branch: return with_branch
    let without_branch = weighted_mis(square, weights, n, exclude_remaining, current)
    if with_branch > without_branch: return with_branch
    return without_branch
