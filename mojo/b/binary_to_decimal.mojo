from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("binary_to_decimal")
fn binary_to_decimal(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 63: return -1
    var value: Int64 = 0
    for i in range(Int(length)):
        let bit = input[i]
        if bit != 0 and bit != 1: return -1
        value = value * 2 + bit
    return value
