from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_M = 8
alias MAX_PARSEABLE = 19

fn multiply_in_field(left_value: UInt64, right_value: UInt64) -> UInt64:
    var shifted = left_value
    var multiplier = right_value
    var product: UInt64 = 0
    for _ in range(64):
        if (multiplier & 1) != 0:
            product ^= shifted
        let carry = shifted >> 63
        shifted <<= 1
        if carry != 0:
            shifted ^= UInt64(0x1b)
        multiplier >>= 1
    return product

@export("convolution_f2_64")
fn convolution_f2_64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE):
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 1 or input[1] > MAX_M:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2 + n + m):
        return -1
    let count = n + m - 1
    let needed = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2

    var a = InlineArray[UInt64, 8](fill=0)
    var b = InlineArray[UInt64, 8](fill=0)
    var product = InlineArray[UInt64, 15](fill=0)
    for i in range(n):
        a[i] = bitcast[UInt64](input[2 + i])
    for j in range(m):
        b[j] = bitcast[UInt64](input[2 + n + j])
    for i in range(n):
        for j in range(m):
            product[i + j] ^= multiply_in_field(a[i], b[j])
    for i in range(count):
        for byte in range(8):
            output[8 * i + byte] = UInt8((product[i] >> (8 * byte)) & UInt64(255))
    return Int64(needed)
