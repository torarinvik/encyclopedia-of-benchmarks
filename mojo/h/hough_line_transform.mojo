"""Integer-only Hough accumulator with four fixed quantized normals."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PARSEABLE_INPUT_LENGTH = 67
comptime RHO_COUNT = 29
comptime OUTPUT_BYTES = 116

@export("hough_line_transform")
fn hough_line_transform(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
            length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    let height_value = input[0]
    let width_value = input[1]
    if height_value < 1 or height_value > 8 or width_value < 1 or width_value > 8:
        return -1
    let height = Int(height_value)
    let width = Int(width_value)
    let cells = height * width
    if length != c_size_t(2 + cells):
        return -1
    for index in range(cells):
        if input[index + 2] != 0 and input[index + 2] != 1:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(OUTPUT_BYTES):
        return -2

    var accumulator = InlineArray[UInt8, OUTPUT_BYTES](fill=0)
    for row in range(height):
        for column in range(width):
            if input[2 + row * width + column] == 0:
                continue
            let x = column
            let y = row
            var rho = InlineArray[Int, 4](fill=0)
            rho[0] = x
            rho[1] = x + y
            rho[2] = y
            rho[3] = -x + y
            for angle in range(4):
                let bin = angle * RHO_COUNT + rho[angle] + 14
                accumulator[bin] += 1
    for index in range(OUTPUT_BYTES):
        output[index] = accumulator[index]
    return Int64(OUTPUT_BYTES)
