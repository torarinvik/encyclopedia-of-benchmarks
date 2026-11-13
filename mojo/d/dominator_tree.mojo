from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn count_bits(value: UInt64) -> Int:
    var bits = value
    var count = 0
    while bits != 0:
        bits &= bits - 1
        count += 1
    return count

@export("dominator_tree")
fn dominator_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 4097: return -1
    let n64 = input[0]
    let root64 = input[1]
    let m64 = input[2]
    if n64 < 1 or n64 > 63 or root64 < 0 or root64 >= n64 or m64 < 0 or m64 > 2047: return -1
    let n = Int(n64)
    let root = Int(root64)
    let m = Int(m64)
    if length != c_size_t(3 + 2 * m): return -1
    var outgoing = InlineArray[UInt64, 63](fill=0)
    for edge in range(m):
        let u = input[3 + 2 * edge]
        let v = input[4 + 2 * edge]
        if u < 0 or u >= n64 or v < 0 or v >= n64: return -1
        outgoing[Int(u)] |= UInt64(1) << UInt(v)
    var reachable = UInt64(1) << UInt(root)
    var frontier = reachable
    while frontier != 0:
        var discovered = UInt64(0)
        for vertex in range(n):
            if frontier & (UInt64(1) << UInt(vertex)) != 0: discovered |= outgoing[vertex]
        discovered &= ~reachable
        reachable |= discovered
        frontier = discovered
    var dominators = InlineArray[UInt64, 63](fill=0)
    for vertex in range(n):
        if reachable & (UInt64(1) << UInt(vertex)) != 0: dominators[vertex] = reachable
    dominators[root] = UInt64(1) << UInt(root)
    var changed = True
    while changed:
        changed = False
        for vertex in range(n):
            let bit = UInt64(1) << UInt(vertex)
            if vertex == root or reachable & bit == 0: continue
            var common = reachable
            for predecessor in range(n):
                if reachable & (UInt64(1) << UInt(predecessor)) != 0 and outgoing[predecessor] & bit != 0:
                    common &= dominators[predecessor]
            let updated = common | bit
            if updated != dominators[vertex]:
                dominators[vertex] = updated
                changed = True
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for vertex in range(n):
        let bit = UInt64(1) << UInt(vertex)
        if reachable & bit == 0:
            output[vertex] = 255
        elif vertex == root:
            output[vertex] = UInt8(root)
        else:
            let strict = dominators[vertex] & ~bit
            var best = root
            var best_depth = 0
            for candidate in range(n):
                if strict & (UInt64(1) << UInt(candidate)) != 0:
                    let depth = count_bits(dominators[candidate])
                    if depth > best_depth:
                        best = candidate
                        best_depth = depth
            output[vertex] = UInt8(best)
    return Int64(n)
