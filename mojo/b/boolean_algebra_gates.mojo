from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("boolean_algebra_gates")
fn boolean_algebra_gates(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let gate = input[0]; let count = input[1]
    if gate < 0 or gate > 5 or count < 0 or count > 4096 or length != c_size_t(2 + count): return -1
    for i in range(Int(count)):
        if input[2 + i] != 0 and input[2 + i] != 1: return -1
    if gate == 2:
        if count != 1: return -1
        return 1 - input[2]
    if gate == 0 or gate == 4:
        var out: Int64 = 1
        for i in range(Int(count)): out = out & input[2 + i]
        return out if gate == 0 else 1 - out
    if gate == 1 or gate == 5:
        var out: Int64 = 0
        for i in range(Int(count)): out = out | input[2 + i]
        return out if gate == 1 else 1 - out
    var out: Int64 = 0
    for i in range(Int(count)): out = out ^ input[2 + i]
    return out
