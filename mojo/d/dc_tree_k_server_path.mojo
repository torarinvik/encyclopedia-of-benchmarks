from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("dc_tree_k_server_path")
fn dc_tree_k_server_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 18: return -1
    if input[0] < 2 or input[0] > 4 or input[1] < 1 or input[1] > 12: return -1
    let k = Int(input[0])
    let q = Int(input[1])
    if Int(length) != 2 + k + q: return -1
    var positions = InlineArray[Int64, 4](fill=0)
    for i in range(k):
        if input[2 + i] < 0 or input[2 + i] > 15: return -1
        positions[i] = input[2 + i]
    for i in range(q):
        if input[2 + k + i] < 0 or input[2 + k + i] > 15: return -1
    var staged = InlineArray[Int64, 60](fill=0)
    var used = 0
    for request in range(q):
        let target = input[2 + k + request]
        var active = InlineArray[Bool, 4](fill=False)
        var count = 0
        var nearest: Int64 = 16
        for i in range(k):
            var duplicate = False
            for j in range(i):
                if positions[j] == positions[i]: duplicate = True
            if duplicate: continue
            active[i] = True
            count += 1
            var distance = positions[i] - target
            if distance < 0: distance = -distance
            if distance < nearest: nearest = distance
        staged[used] = nearest * Int64(count)
        used += 1
        for i in range(k):
            if active[i]:
                if positions[i] < target: positions[i] += nearest
                elif positions[i] > target: positions[i] -= nearest
            staged[used] = positions[i]
            used += 1
    let bytes = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(used):
        var bits = UInt64(staged[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
