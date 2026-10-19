from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("bitwisemin")
fn bitwisemin(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4096: return -1
    var result = input[0]
    if result < 0 or result > 2_147_483_647: return -1
    for i in range(1, Int(length)):
        let value = input[i]
        if value < 0 or value > 2_147_483_647: return -1
        let difference = result - value; let sign = (difference >> 31) & 1
        result = result - sign * difference
    return result
