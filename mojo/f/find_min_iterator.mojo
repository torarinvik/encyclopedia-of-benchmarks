from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_min_iterator")
fn find_min_iterator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129: return -1
    let n = input[0]
    if n < 0 or n > 128 or length != n + 1 or n == 0: return -1
    var minimum: Int64 = 2147483647
    for i in range(n):
        let value = input[i + 1]
        if value < 0 or value > 2147483647: return -1
        if value < minimum: minimum = value
    return minimum
