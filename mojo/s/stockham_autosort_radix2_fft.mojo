from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_SCALARS = 128

fn stockham_stage(inout source: InlineArray[Float64, MAX_SCALARS],
                  inout destination: InlineArray[Float64, MAX_SCALARS],
                  n: Int, stride: Int):
    for j in range(n // 2):
        let column = j % stride
        let group = j // stride
        let base = group * 2 * stride + column
        let angle = -6.283185307179586476925286766559 * Float64(column) / Float64(2 * stride)
        let cosine = cos(angle)
        let sine = sin(angle)
        let left = 2 * j
        let right = 2 * (j + n // 2)
        let product_real = cosine * source[right] - sine * source[right + 1]
        let product_imag = cosine * source[right + 1] + sine * source[right]
        let first_real = source[left]
        let first_imag = source[left + 1]
        let out_left = 2 * base
        let out_right = 2 * (base + stride)
        destination[out_left] = first_real + product_real
        destination[out_left + 1] = first_imag + product_imag
        destination[out_right] = first_real - product_real
        destination[out_right + 1] = first_imag - product_imag

@export("stockham_autosort_radix2_fft")
fn stockham_autosort_radix2_fft(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or input_length > 130:
        return -1
    for i in range(input_length):
        if not isfinite(input[i]):
            return -1
    let n_value = input[0]
    if n_value < 1.0 or n_value > 64.0:
        return -1
    let n = Int(n_value)
    if Float64(n) != n_value or (n & (n - 1)) != 0 or input_length != c_size_t(1 + 2 * n):
        return -1
    for i in range(2 * n):
        if input[i + 1] < -8.0 or input[i + 1] > 8.0:
            return -1

    var first = InlineArray[Float64, MAX_SCALARS](0.0)
    var second = InlineArray[Float64, MAX_SCALARS](0.0)
    for i in range(2 * n):
        first[i] = input[i + 1]
    var source_is_first = True
    var stride = 1
    while stride < n:
        if source_is_first:
            stockham_stage(first, second, n, stride)
        else:
            stockham_stage(second, first, n, stride)
        source_is_first = not source_is_first
        stride *= 2

    let needed = 2 * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2
    for i in range(needed):
        if source_is_first:
            output[i] = first[i]
        else:
            output[i] = second[i]
    return Int64(needed)
