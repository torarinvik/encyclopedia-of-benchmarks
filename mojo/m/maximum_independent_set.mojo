from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 22
comptime MAX_INPUT = 465

fn mis_popcount(bits_input: UInt64) -> Int:
    var bits = bits_input
    var count = 0
    while bits != 0:
        bits = bits & (bits - UInt64(1))
        count += 1
    return count

fn mis_clique_cover_bound(adjacency: InlineArray[UInt64, MAX_N],
                          remaining_input: UInt64) -> Int:
    var remaining = remaining_input
    var cliques = 0
    while remaining != 0:
        cliques += 1
        var candidates = remaining
        while candidates != 0:
            var vertex = 0
            while (candidates & (UInt64(1) << vertex)) == 0:
                vertex += 1
            let bit = UInt64(1) << vertex
            remaining = remaining & (~bit)
            candidates = candidates & (~bit) & adjacency[vertex]
    return cliques

fn mis_search(adjacency: InlineArray[UInt64, MAX_N],
              remaining: UInt64, chosen: Int, inout best: Int):
    if remaining == 0:
        best = max(best, chosen)
        return
    if chosen + mis_popcount(remaining) <= best: return
    if chosen + mis_clique_cover_bound(adjacency, remaining) <= best: return
    var vertices = remaining
    var branch = 0
    var branch_degree = -1
    while vertices != 0:
        var vertex = 0
        while (vertices & (UInt64(1) << vertex)) == 0:
            vertex += 1
        let bit = UInt64(1) << vertex
        let degree = mis_popcount(adjacency[vertex] & remaining)
        if degree > branch_degree:
            branch = vertex
            branch_degree = degree
        vertices = vertices & (~bit)
    let bit = UInt64(1) << branch
    mis_search(adjacency, remaining & (~bit) & (~adjacency[branch]), chosen + 1, best)
    mis_search(adjacency, remaining & (~bit), chosen, best)

@export("maximum_independent_set")
fn maximum_independent_set(input: UnsafePointer[Int64, ImmutAnyOrigin],
                           length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 0 or n64 > Int64(MAX_N): return -1
    let max_edges = n64 * (n64 - 1) / 2
    if m64 < 0 or m64 > max_edges or length != c_size_t(2 + 2 * m64): return -1
    var adjacency = InlineArray[UInt64, MAX_N](fill=0)
    for edge in range(Int(m64)):
        let u64 = input[2 + 2 * edge]
        let v64 = input[3 + 2 * edge]
        if u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64: return -1
        let u = Int(u64)
        let v = Int(v64)
        let v_bit = UInt64(1) << v
        if (adjacency[u] & v_bit) != 0: return -1
        adjacency[u] = adjacency[u] | v_bit
        adjacency[v] = adjacency[v] | (UInt64(1) << u)
    var best = 0
    let all_vertices = (UInt64(1) << Int(n64)) - UInt64(1)
    mis_search(adjacency, all_vertices, 0, best)
    return Int64(best)
