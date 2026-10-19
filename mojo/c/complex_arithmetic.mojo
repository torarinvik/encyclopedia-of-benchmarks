from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("complex_arithmetic")
fn complex_arithmetic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5: return -1
    let op = input[0]
    let ar = input[1]
    let ai = input[2]
    let br = input[3]
    let bi = input[4]
    if op < 0 or op > 5 or ar < -100000 or ar > 100000 or ai < -100000 or ai > 100000 or br < -100000 or br > 100000 or bi < -100000 or bi > 100000: return -1
    var real: Int64 = 0
    var imag: Int64 = 0
    if op == 0:
        real = ar + br
        imag = ai + bi
    elif op == 1:
        real = ar - br
        imag = ai - bi
    elif op == 2:
        real = ar * br - ai * bi
        imag = ar * bi + ai * br
    elif op == 3:
        let denominator = br * br + bi * bi
        if denominator == 0: return -1
        let real_numerator = ar * br + ai * bi
        let imag_numerator = ai * br - ar * bi
        if real_numerator % denominator != 0 or imag_numerator % denominator != 0: return -1
        real = real_numerator / denominator
        imag = imag_numerator / denominator
    elif op == 4:
        real = ar
        imag = -ai
    else:
        real = 1 if ar == br and ai == bi else 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 16: return -2
    let real_bits = UInt64(real)
    let imag_bits = UInt64(imag)
    for b in range(8):
        output[b] = UInt8((real_bits >> (8 * b)) & 255)
        output[8 + b] = UInt8((imag_bits >> (8 * b)) & 255)
    return 2
