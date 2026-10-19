from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("binary_multiplication")
fn binary_multiplication(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let av = input[0]; let bv = input[1]
    if av < 0 or av > 1_000_000_000 or bv < 0 or bv > 1_000_000_000: return -1
    var a = UInt64(av); var b = UInt64(bv); var result: UInt64 = 0
    while b > 0:
        if (b & 1) != 0: result += a
        a <<= 1; b >>= 1
    return Int64(result)
