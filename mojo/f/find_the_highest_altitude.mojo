from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_the_highest_altitude")
fn find_the_highest_altitude(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1
    let n = input[0]
    if n < 0 or n > 1024 or length != n + 1: return -1
    var altitude: Int64 = 0
    var maximum: Int64 = 0
    for i in range(n):
        let gain = input[i + 1]
        if gain < -2147483648 or gain > 2147483647: return -1
        altitude += gain
        if altitude > maximum: maximum = altitude
    return maximum
