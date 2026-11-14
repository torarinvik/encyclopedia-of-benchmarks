from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pfr_local_forward_decision")
fn pfr_local_forward_decision(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let angle = input[0]
    let draw = input[1]
    if angle < 0 or angle > 180000000 or draw < 0 or draw >= 1000000:
        return -1
    let forward: UInt8 = if angle >= 134000000 or 180 * draw < angle: 1 else: 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    output[0] = forward
    for i in range(1, 8): output[i] = 0
    return 8
