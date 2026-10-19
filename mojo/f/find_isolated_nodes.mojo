from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("find_isolated_nodes")
fn find_isolated_nodes(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65 or (length - 1) % 2 != 0: return -2
    let vertices = values[0]
    if vertices < 0 or vertices > 64: return -2
    var adjacency = InlineArray[UInt64, 64](0)
    let edges = (length - 1) / 2
    for e in range(edges):
        let source = values[1 + 2 * e]
        let dest = values[2 + 2 * e]
        if source < 0 or dest < 0 or source >= vertices or dest >= vertices: return -2
        adjacency[source] = adjacency[source] | (UInt64(1) << dest)
    var isolated = InlineArray[UInt8, 64](0)
    var count: Int64 = 0
    for v in range(vertices):
        if adjacency[v] == 0:
            isolated[count] = UInt8(v)
            count += 1
    if capacity < count or (count != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(count): output[i] = isolated[i]
    return count
