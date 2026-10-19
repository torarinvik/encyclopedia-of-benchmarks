from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_I64: UInt64 = 9_223_372_036_854_775_807
@export("binary_exponentiation")
fn binary_exponentiation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let base_value = input[0]; let exponent_value = input[1]
    if base_value < 0 or base_value > 2_147_483_647 or exponent_value < 0 or exponent_value > 2_147_483_647: return -1
    var base = UInt64(base_value); var exponent = UInt64(exponent_value); var result: UInt64 = 1
    while exponent != 0:
        if (exponent & 1) != 0:
            if base != 0 and result > MAX_I64 // base: return -1
            result *= base
        exponent >>= 1
        if exponent != 0:
            if base != 0 and base > MAX_I64 // base: return -1
            base *= base
    return Int64(result)
