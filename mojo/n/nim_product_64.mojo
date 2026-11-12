from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn nim_product(a: UInt64, b: UInt64, width: Int) -> UInt64:
    if width == 1: return a & b
    let half = width // 2
    let mask = (UInt64(1) << half) - UInt64(1)
    let a_low = a & mask
    let a_high = a >> half
    let b_low = b & mask
    let b_high = b >> half
    let low_product = nim_product(a_low, b_low, half)
    let high_product = nim_product(a_high, b_high, half)
    let cross = nim_product(a_low ^ a_high, b_low ^ b_high, half) ^ low_product ^ high_product
    let constant = UInt64(1) << (half - 1)
    let low = low_product ^ nim_product(high_product, constant, half)
    let high = cross ^ high_product
    return low ^ (high << half)

@export("nim_product_64")
fn nim_product_64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                  output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    for index in range(4):
        if input[index] < 0 or input[index] > 4294967295: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 8: return -2

    let a = UInt64(input[0]) | (UInt64(input[1]) << 32)
    let b = UInt64(input[2]) | (UInt64(input[3]) << 32)
    let result = nim_product(a, b, 64)
    for index in range(8):
        output[index] = UInt8((result >> (index * 8)) & UInt64(255))
    return 8
