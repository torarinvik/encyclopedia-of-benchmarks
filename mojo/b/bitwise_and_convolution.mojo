from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_SIZE = 1 << MAX_N
alias MAX_INPUT_LENGTH = 1 + 2 * MAX_SIZE
alias MODULUS = Int64(998244353)

def bitwise_and_convolution_store_i64(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: usize, value: Int64
) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("bitwise_and_convolution")
fn bitwise_and_convolution(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    let size = 1 << n
    if length != c_size_t(1 + 2 * size):
        return -1
    for index in range(2 * size):
        let value = input[1 + index]
        if value < 0 or value >= MODULUS:
            return -1
    let output_bytes = 8 * size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var a = InlineArray[Int64, MAX_SIZE]()
    var b = InlineArray[Int64, MAX_SIZE]()
    for index in range(size):
        a[index] = input[1 + index]
        b[index] = input[1 + size + index]
    for bit in range(n):
        let bit_mask = 1 << bit
        for mask in range(size):
            if (mask & bit_mask) == 0:
                a[mask] = (a[mask] + a[mask | bit_mask]) % MODULUS
                b[mask] = (b[mask] + b[mask | bit_mask]) % MODULUS
    for mask in range(size):
        a[mask] = (a[mask] * b[mask]) % MODULUS
    for bit in range(n):
        let bit_mask = 1 << bit
        for mask in range(size):
            if (mask & bit_mask) == 0:
                a[mask] = a[mask] - a[mask | bit_mask]
                if a[mask] < 0:
                    a[mask] = a[mask] + MODULUS
    for mask in range(size):
        bitwise_and_convolution_store_i64(output, 8 * mask, a[mask])
    return Int64(output_bytes)
