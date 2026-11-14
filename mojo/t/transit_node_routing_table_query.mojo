from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("transit_node_routing_table_query")
fn transit_node_routing_table_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 11 or length > 86: return -1
    let count = input[0]
    if count < 1 or count > 8 or input[1] < 0 or input[1] >= 32 or input[2] < 0 or input[2] >= 32 or input[3] != 1: return -1
    let n = Int(count)
    var at = 4
    let forward_count = input[at]
    at += 1
    if forward_count < 1 or forward_count > 4 or forward_count > count or at + 2 * Int(forward_count) > Int(length): return -1
    var forward = InlineArray[Int, 4](fill=0)
    var source_distance = InlineArray[Int64, 4](fill=0)
    var seen = InlineArray[Bool, 8](fill=False)
    for i in range(Int(forward_count)):
        let vertex = input[at]; let distance = input[at + 1]
        at += 2
        if vertex < 0 or vertex >= count or distance < 0 or distance > 1000000: return -1
        if seen[Int(vertex)]: return -1
        seen[Int(vertex)] = True
        forward[i] = Int(vertex)
        source_distance[i] = distance
    if at >= Int(length): return -1
    let backward_count = input[at]
    at += 1
    if backward_count < 1 or backward_count > 4 or backward_count > count or at + 2 * Int(backward_count) > Int(length): return -1
    var backward = InlineArray[Int, 4](fill=0)
    var target_distance = InlineArray[Int64, 4](fill=0)
    for i in range(8): seen[i] = False
    for i in range(Int(backward_count)):
        let vertex = input[at]; let distance = input[at + 1]
        at += 2
        if vertex < 0 or vertex >= count or distance < 0 or distance > 1000000: return -1
        if seen[Int(vertex)]: return -1
        seen[Int(vertex)] = True
        backward[i] = Int(vertex)
        target_distance[i] = distance
    if at + n * n != Int(length): return -1
    var table = InlineArray[Int64, 64](fill=0)
    for i in range(n):
        for j in range(n):
            let distance = input[at]
            at += 1
            if distance < 0 or distance > 1000000 or (i == j and distance != 0): return -1
            table[8 * i + j] = distance
    var best: Int64 = 3000001
    var best_u = 0
    var best_v = 0
    for i in range(Int(forward_count)):
        for j in range(Int(backward_count)):
            let u = forward[i]; let v = backward[j]
            let distance = source_distance[i] + table[8 * u + v] + target_distance[j]
            if distance < best or (distance == best and (u < best_u or (u == best_u and v < best_v))):
                best = distance
                best_u = u
                best_v = v
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    for slot in range(3):
        let value = if slot == 0: best elif slot == 1: Int64(best_u) else: Int64(best_v)
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 24
