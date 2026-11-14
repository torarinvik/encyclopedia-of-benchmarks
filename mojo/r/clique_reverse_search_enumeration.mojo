from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn visit(n: Int, adjacency: List[Int], clique: Int, mut masks: List[UInt8]):
    masks.append(UInt8(clique))
    var minimum = n
    for vertex in range(n):
        if clique & (1 << vertex) != 0:
            minimum = vertex
            break
    for vertex in range(minimum):
        let bit = 1 << vertex
        if clique & bit == 0 and adjacency[vertex] & clique == clique:
            visit(n, adjacency, clique|bit, masks)

@export("clique_reverse_search_enumeration")
fn clique_reverse_search_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 9: return -1
    let nv = input[0]
    if nv < 1 or nv > 8: return -1
    let n = Int(nv)
    if length != c_size_t(n+1): return -1
    var adjacency = List[Int](capacity=8)
    for vertex in range(n):
        let raw = input[1+vertex]
        if raw < 0 or raw >= Int64(1 << n) or raw & Int64(1 << vertex) != 0: return -1
        adjacency.append(Int(raw))
    for u in range(n):
        for v in range(u+1, n):
            if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1): return -1
    var masks = List[UInt8](capacity=256)
    visit(n, adjacency, 0, masks)
    let required = 8+len(masks)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var count = UInt64(len(masks))
    for byte in range(8):
        output[byte] = UInt8(count & UInt64(255))
        count = count >> 8
    for i in range(len(masks)): output[8+i] = masks[i]
    return Int64(required)
