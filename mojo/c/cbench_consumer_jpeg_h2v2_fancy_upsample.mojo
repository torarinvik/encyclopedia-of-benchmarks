# Independent bounded IJG upsampling adaptation; see package README and LICENSE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_jpeg_h2v2_fancy_upsample")
fn cbench_consumer_jpeg_h2v2_fancy_upsample(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 130:
        return -1
    let width_value = input[0]
    let height_value = input[1]
    if width_value < 3 or width_value > 16 or height_value < 1 or height_value > 8:
        return -1
    let width = Int(width_value)
    let height = Int(height_value)
    let pixels = width * height
    if length != c_size_t(2 + pixels):
        return -1
    var source = InlineArray[Int64, 128](fill=0)
    for i in range(pixels):
        let value = input[2 + i]
        if value < 0 or value > 255:
            return -1
        source[i] = value
    let bytes = 4 * pixels
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var staged = InlineArray[UInt8, 512](fill=0)
    var at = 0
    for row in range(height):
        for side in range(2):
            var far = row
            if side == 0 and row > 0:
                far = row - 1
            elif side == 1 and row + 1 < height:
                far = row + 1
            var sums = InlineArray[Int64, 16](fill=0)
            for column in range(width):
                sums[column] = 3 * source[row * width + column] + source[far * width + column]
            staged[at] = UInt8((4 * sums[0] + 8) >> 4)
            staged[at + 1] = UInt8((3 * sums[0] + sums[1] + 7) >> 4)
            at += 2
            for column in range(1, width - 1):
                staged[at] = UInt8((3 * sums[column] + sums[column - 1] + 8) >> 4)
                staged[at + 1] = UInt8((3 * sums[column] + sums[column + 1] + 7) >> 4)
                at += 2
            staged[at] = UInt8((3 * sums[width - 1] + sums[width - 2] + 8) >> 4)
            staged[at + 1] = UInt8((4 * sums[width - 1] + 7) >> 4)
            at += 2
    for i in range(bytes):
        output[i] = staged[i]
    return Int64(bytes)
