from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("bitwisemax")
fn bitwisemax(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let a = input[0]; let b = input[1]
    if a < 0 or a > 2_147_483_647 or b < 0 or b > 2_147_483_647: return -1
    let difference = a - b
    let sign = (difference >> 31) & 1
    return a - sign * difference
