from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("incremental_scc")
fn incremental_scc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > 8 or m64 < 0 or m64 > 32: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    for edge in range(m):
        let u = input[2 + 2 * edge]
        let v = input[3 + 2 * edge]
        if u < 0 or u >= n64 or v < 0 or v >= n64: return -1
    var reachable = InlineArray[Bool, 64](fill=False)
    for vertex in range(n): reachable[8 * vertex + vertex] = True
    var checksum: Int64 = 0
    for edge in range(m):
        let u = Int(input[2 + 2 * edge])
        let v = Int(input[3 + 2 * edge])
        var predecessors = InlineArray[Bool, 8](fill=False)
        var successors = InlineArray[Bool, 8](fill=False)
        for vertex in range(n):
            predecessors[vertex] = reachable[8 * vertex + u]
            successors[vertex] = reachable[8 * v + vertex]
        for first in range(n):
            for second in range(n):
                if predecessors[first] and successors[second]: reachable[8 * first + second] = True
        var assigned = InlineArray[Bool, 8](fill=False)
        var components = 0
        for first in range(n):
            if not assigned[first]:
                components += 1
                for vertex in range(first, n):
                    if reachable[8 * first + vertex] and reachable[8 * vertex + first]: assigned[vertex] = True
        checksum += Int64(edge + 1) * Int64(components)
    return checksum
