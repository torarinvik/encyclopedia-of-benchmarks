from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct FFTValue:
    var real: Float64
    var imag: Float64

fn convolution_fft_transform(values_arg: InlineArray[FFTValue, 128], n: Int64, inverse: Bool) -> InlineArray[FFTValue, 128]:
    var values = values_arg
    var reverse: Int64 = 0
    for position in range(1, n):
        var bit = n >> 1
        while bit != 0 and (reverse & bit) != 0:
            reverse ^= bit
            bit >>= 1
        reverse ^= bit
        if position < reverse:
            let temp = values[position]
            values[position] = values[reverse]
            values[reverse] = temp
    var block: Int64 = 2
    while block <= n:
        let direction = -1.0 if inverse else 1.0
        let angle = -2.0 * 3.14159265358979323846 / Float64(block) * direction
        let step_real = cos(angle)
        let step_imag = sin(angle)
        var start: Int64 = 0
        while start < n:
            var weight_real: Float64 = 1.0
            var weight_imag: Float64 = 0.0
            for offset in range(block / 2):
                let first = start + offset
                let second = first + block / 2
                let product_real = weight_real * values[second].real - weight_imag * values[second].imag
                let product_imag = weight_real * values[second].imag + weight_imag * values[second].real
                let first_real = values[first].real
                let first_imag = values[first].imag
                values[first].real = first_real + product_real
                values[first].imag = first_imag + product_imag
                values[second].real = first_real - product_real
                values[second].imag = first_imag - product_imag
                let next_real = weight_real * step_real - weight_imag * step_imag
                weight_imag = weight_real * step_imag + weight_imag * step_real
                weight_real = next_real
            start += block
        block *= 2
    if inverse:
        for i in range(n):
            values[i].real /= Float64(n)
            values[i].imag /= Float64(n)
    return values

@export("convolution_fft")
fn convolution_fft(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130: return -1
    let a_count = input[0]
    let b_count = input[1]
    if a_count < 1 or a_count > 64 or b_count < 1 or b_count > 64 or length != 2 + a_count + b_count: return -1
    for i in range(a_count + b_count):
        if input[2 + i] < -64 or input[2 + i] > 64: return -1
    let result_count = a_count + b_count - 1
    let byte_count = result_count * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < byte_count: return -2
    var fft_length: Int64 = 1
    while fft_length < result_count: fft_length *= 2
    var a = InlineArray[FFTValue, 128](FFTValue(0.0, 0.0))
    var b = InlineArray[FFTValue, 128](FFTValue(0.0, 0.0))
    for i in range(a_count): a[i].real = Float64(input[i + 2]) / 16.0
    for i in range(b_count): b[i].real = Float64(input[a_count + i + 2]) / 16.0
    a = convolution_fft_transform(a, fft_length, False)
    b = convolution_fft_transform(b, fft_length, False)
    var product = InlineArray[FFTValue, 128](FFTValue(0.0, 0.0))
    for i in range(fft_length):
        product[i].real = a[i].real * b[i].real - a[i].imag * b[i].imag
        product[i].imag = a[i].real * b[i].imag + a[i].imag * b[i].real
    product = convolution_fft_transform(product, fft_length, True)
    for i in range(result_count):
        let real_bits = bitcast[UInt64](product[i].real)
        let imag_bits = bitcast[UInt64](product[i].imag)
        for byte in range(8):
            output[16 * i + byte] = UInt8((real_bits >> (8 * byte)) & 255)
            output[16 * i + 8 + byte] = UInt8((imag_bits >> (8 * byte)) & 255)
    return byte_count
