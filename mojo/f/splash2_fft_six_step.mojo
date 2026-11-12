from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import cos, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_OUTPUT = 128

fn splash2_fft_transpose(inout source: InlineArray[Float64, MAX_OUTPUT],
                         inout destination: InlineArray[Float64, MAX_OUTPUT], side: Int):
    for row in range(side):
        for column in range(side):
            let from_index = 2 * (row * side + column)
            let to_index = 2 * (column * side + row)
            destination[to_index] = source[from_index]
            destination[to_index + 1] = source[from_index + 1]

fn splash2_fft_row(inout data: InlineArray[Float64, MAX_OUTPUT], base: Int, side: Int):
    var reverse = 0
    for position in range(1, side):
        var bit = side >> 1
        while (reverse & bit) != 0:
            reverse ^= bit
            bit >>= 1
        reverse ^= bit
        if position < reverse:
            let left = 2 * (base + position)
            let right = 2 * (base + reverse)
            let real = data[left]
            data[left] = data[right]
            data[right] = real
            let imag = data[left + 1]
            data[left + 1] = data[right + 1]
            data[right + 1] = imag

    var block = 2
    while block <= side:
        let half = block / 2
        let angle_step = 6.283185307179586476925286766559 / Float64(block)
        var start = 0
        while start < side:
            for offset in range(half):
                let angle = angle_step * Float64(offset)
                let weight_real = cos(angle)
                let weight_imag = -sin(angle)
                let first = 2 * (base + start + offset)
                let second = 2 * (base + start + offset + half)
                let product_real = weight_real * data[second] - weight_imag * data[second + 1]
                let product_imag = weight_real * data[second + 1] + weight_imag * data[second]
                let first_real = data[first]
                let first_imag = data[first + 1]
                data[first] = first_real + product_real
                data[first + 1] = first_imag + product_imag
                data[second] = first_real - product_real
                data[second + 1] = first_imag - product_imag
            start += block
        block *= 2

@export("splash2_fft_six_step")
fn splash2_fft_six_step(input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
                        output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 9 or input_length > 130:
        return -1
    let side_value = input[0]
    if side_value != 2.0 and side_value != 4.0 and side_value != 8.0: return -1
    let side = Int(side_value)
    let points = side * side
    if input_length != c_size_t(1 + 2 * points): return -1
    for i in range(2 * points):
        let value = input[i + 1]
        if value != value or value < -8.0 or value > 8.0: return -1

    let needed = 2 * points
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2

    var first_matrix = InlineArray[Float64, MAX_OUTPUT](0.0)
    var second_matrix = InlineArray[Float64, MAX_OUTPUT](0.0)
    for i in range(needed): first_matrix[i] = input[i + 1]
    splash2_fft_transpose(first_matrix, second_matrix, side)
    for row in range(side): splash2_fft_row(second_matrix, row * side, side)

    for row in range(side):
        for column in range(side):
            let index = 2 * (row * side + column)
            let angle = 6.283185307179586476925286766559 * Float64(row * column) / Float64(points)
            let cosine = cos(angle)
            let sine = sin(angle)
            let real = second_matrix[index]
            let imag = second_matrix[index + 1]
            second_matrix[index] = cosine * real + sine * imag
            second_matrix[index + 1] = cosine * imag - sine * real

    splash2_fft_transpose(second_matrix, first_matrix, side)
    for row in range(side): splash2_fft_row(first_matrix, row * side, side)
    splash2_fft_transpose(first_matrix, second_matrix, side)
    for i in range(needed): output[i] = second_matrix[i]
    return Int64(needed)
