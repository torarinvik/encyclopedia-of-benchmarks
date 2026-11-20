from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 24
comptime MAX_PARSEABLE_INPUT = 26

fn clique_bit_count(bits_input: UInt64) -> Int:
    var bits = bits_input
    var count = 0
    while bits != 0:
        bits = bits & (bits - UInt64(1))
        count += 1
    return count

fn clique_search(adjacency: InlineArray[UInt64, MAX_VERTICES],
                 suffix_best: InlineArray[Int, MAX_VERTICES],
                 candidates: UInt64, chosen: Int, inout best: Int) -> Bool:
    if candidates == 0:
        if chosen > best:
            best = chosen
            return True
        return False
    var remaining = candidates
    while remaining != 0:
        if chosen + clique_bit_count(remaining) <= best: return False
        var vertex = 0
        while (remaining & (UInt64(1) << vertex)) == 0:
            vertex += 1
        let bit = UInt64(1) << vertex
        remaining = remaining & (~bit)
        if chosen + suffix_best[vertex] <= best: return False
        if clique_search(adjacency, suffix_best, remaining & adjacency[vertex], chosen + 1, best):
            return True
    return False

@export("oi_wiki_maximum_clique_branch_bound")
fn oi_wiki_maximum_clique_branch_bound(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    let n64 = input[0]
    if n64 < 0 or n64 > Int64(MAX_VERTICES) or length != c_size_t(1 + n64): return -1
    let n = Int(n64)
    let domain = (UInt64(1) << n) - UInt64(1)
    var adjacency = InlineArray[UInt64, MAX_VERTICES](fill=UInt64(0))
    for vertex in range(n):
        let row = input[1 + vertex]
        if row < 0 or (UInt64(row) & (~domain)) != 0: return -1
        adjacency[vertex] = UInt64(row)
        if (adjacency[vertex] & (UInt64(1) << vertex)) != 0: return -1
    for left in range(n):
        for right in range(left + 1, n):
            let forward = (adjacency[left] & (UInt64(1) << right)) != 0
            let reverse = (adjacency[right] & (UInt64(1) << left)) != 0
            if forward != reverse: return -1
    var suffix_best = InlineArray[Int, MAX_VERTICES](fill=0)
    var best = 0
    var root = n
    while root > 0:
        root -= 1
        let greater = domain & (~((UInt64(1) << (root + 1)) - UInt64(1)))
        _ = clique_search(adjacency, suffix_best, adjacency[root] & greater, 1, best)
        suffix_best[root] = best
    return Int64(best)
