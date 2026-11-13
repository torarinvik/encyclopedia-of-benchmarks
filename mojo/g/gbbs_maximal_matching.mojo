from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_maximal_matching")
fn gbbs_maximal_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 194: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2 + 3 * mv): return -1
    let m = Int(mv)
    let edge_start = 2 + m
    var order = InlineArray[Int, 64](fill=0)
    var rank_seen = InlineArray[Bool, 64](fill=False)
    var edge_seen = InlineArray[Bool, 256](fill=False)
    for edge in range(m):
        let rank = input[2 + edge]
        if rank < 0 or rank >= mv: return -1
        let r = Int(rank)
        if rank_seen[r]: return -1
        rank_seen[r] = True
        order[r] = edge
        let u = input[edge_start + 2 * edge]
        let v = input[edge_start + 2 * edge + 1]
        if u < 0 or u >= v or v >= nv: return -1
        let slot = Int(u) * 16 + Int(v)
        if edge_seen[slot]: return -1
        edge_seen[slot] = True
    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var matched = InlineArray[Bool, 16](fill=False)
    var selected = InlineArray[Bool, 64](fill=False)
    for rank in range(m):
        let edge = order[rank]
        let u = Int(input[edge_start + 2 * edge])
        let v = Int(input[edge_start + 2 * edge + 1])
        if not matched[u] and not matched[v]:
            matched[u] = True
            matched[v] = True
            selected[edge] = True
    for edge in range(m):
        output[8 * edge] = UInt8(1 if selected[edge] else 0)
        for byte in range(1, 8): output[8 * edge + byte] = 0
    return Int64(bytes)
