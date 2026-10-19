from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_homogenous")
fn count_homogenous(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 4096: return -1
    let count = input[0]
    if length != count + 1: return -1
    for i in range(count):
        if input[1 + i] < 0 or input[1 + i] > 127: return -1
    if count == 0: return 0
    var runs: Int64 = 1
    for i in range(1, count):
        if input[1 + i] != input[i]: runs += 1
    return runs
