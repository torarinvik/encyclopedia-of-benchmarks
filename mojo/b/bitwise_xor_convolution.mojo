from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 8
alias MAX_SIZE = 1 << MAX_N
alias MAX_INPUT_LENGTH = 1 + 2 * MAX_SIZE
alias MODULUS = Int64(998244353)

fn bitwise_xor_transform(inout values: InlineArray[Int64, MAX_SIZE], size: Int):
    var half = 1
    while half < size:
        var block = 0
        while block < size:
            for offset in range(half):
                let left = values[block + offset]
                let right = values[block + half + offset]
                values[block + offset] = (left + right) % MODULUS
                values[block + half + offset] = (left - right + MODULUS) % MODULUS
            block += 2 * half
        half *= 2

fn bitwise_xor_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin],
                         offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("bitwise_xor_convolution")
fn bitwise_xor_convolution(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N: return -1
    let n = Int(n_value)
    let size = 1 << n
    if length != c_size_t(1 + 2 * size): return -1
    for index in range(2 * size):
        let value = input[1 + index]
        if value < 0 or value >= MODULUS: return -1

    let output_bytes = 8 * size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var first = InlineArray[Int64, MAX_SIZE]()
    var second = InlineArray[Int64, MAX_SIZE]()
    for index in range(size):
        first[index] = input[1 + index]
        second[index] = input[1 + size + index]
    bitwise_xor_transform(first, size)
    bitwise_xor_transform(second, size)
    for index in range(size): first[index] = (first[index] * second[index]) % MODULUS
    bitwise_xor_transform(first, size)

    var inverse_size: Int64 = 1
    for _ in range(n): inverse_size = (inverse_size * ((MODULUS + 1) // 2)) % MODULUS
    for index in range(size):
        bitwise_xor_store_i64(output, 8 * index,
                              (first[index] * inverse_size) % MODULUS)
    return Int64(output_bytes)
