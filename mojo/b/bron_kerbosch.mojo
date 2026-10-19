from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn bron_popcount(value0: UInt64) -> Int:
    var value = value0; var count = 0
    while value != 0: count += Int(value & 1); value >>= 1
    return count

fn bron_search(n: Int, adj: List[UInt64], clique: UInt64, p0: UInt64, x0: UInt64) -> UInt64:
    if p0 == 0 and x0 == 0: return UInt64(1) << clique
    var pivot = -1; var greatest = -1
    for v in range(n):
        if ((p0 | x0) & (UInt64(1) << v)) == 0: continue
        let degree = bron_popcount(adj[v])
        if pivot < 0 or degree > greatest: pivot = v; greatest = degree
    var candidates = p0
    if pivot >= 0: candidates = candidates & ~adj[pivot]
    var possible = p0; var excluded = x0; var result: UInt64 = 0
    for v in range(n):
        let bit = UInt64(1) << v
        if (candidates & bit) == 0: continue
        result |= bron_search(n, adj, clique | bit, possible & adj[v], excluded & adj[v])
        possible &= ~bit; excluded |= bit
    return result

@export("bron_kerbosch")
fn bron_kerbosch(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 6: return -1
    let nv = input[0]
    if nv < 0 or nv > 5 or length != c_size_t(nv + 1): return -1
    let n = Int(nv); let mask = (UInt64(1) << n) - 1; var adj = List[UInt64](capacity=n)
    for _ in range(n): adj.append(0)
    for u in range(n):
        let row = input[u + 1]
        if row < 0 or (UInt64(row) & ~mask) != 0: return -1
        adj[u] = UInt64(row) & ~(UInt64(1) << u)
    for u in range(n):
        for v in range(u + 1, n):
            if ((adj[u] >> v) & 1) != ((adj[v] >> u) & 1): return -1
    return Int64(bron_search(n, adj, 0, mask, 0))
