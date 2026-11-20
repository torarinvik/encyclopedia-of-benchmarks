# Clean-room sink-removal implementation of bounded Sugiyama layer assignment.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("sugiyama_longest_path_layer_assignment")
fn sugiyama_longest_path_layer_assignment(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 259: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 0 or n64 > 32 or m64 < 0 or m64 > 128: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1

    var adjacency = List[UInt32](capacity=32)
    var removed = List[Bool](capacity=32)
    var sink_depth = List[Int](capacity=32)
    for _ in range(32):
        adjacency.append(UInt32(0))
        removed.append(False)
        sink_depth.append(0)
    for edge in range(m):
        let source = input[2 + 2 * edge]
        let target = input[3 + 2 * edge]
        if source < 0 or source >= n64 or target < 0 or target >= n64: return -1
        let source_id = Int(source)
        let target_id = Int(target)
        let bit = UInt32(1) << target_id
        if (adjacency[source_id] & bit) != 0: return -1
        adjacency[source_id] = adjacency[source_id] | bit

    var remaining = n
    var depth = 0
    while remaining > 0:
        var sinks = List[Bool](capacity=32)
        for _ in range(32): sinks.append(False)
        var sink_count = 0
        for vertex in range(n):
            if removed[vertex]: continue
            var has_successor = False
            for target in range(n):
                if not removed[target] and (adjacency[vertex] & (UInt32(1) << target)) != 0:
                    has_successor = True
                    break
            if not has_successor:
                sinks[vertex] = True
                sink_count += 1
        if sink_count == 0: return -1
        for vertex in range(n):
            if sinks[vertex]:
                removed[vertex] = True
                sink_depth[vertex] = depth
        remaining -= sink_count
        depth += 1

    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    var staged = List[UInt8](capacity=output_bytes)
    for _ in range(output_bytes): staged.append(UInt8(0))
    for word in range(n + 1):
        var value: UInt64 = UInt64(depth)
        if word > 0: value = UInt64(depth - 1 - sink_depth[word - 1])
        for byte in range(8):
            staged[word * 8 + byte] = UInt8((value >> (byte * 8)) & UInt64(255))
    for index in range(output_bytes): output[index] = staged[index]
    return Int64(output_bytes)
