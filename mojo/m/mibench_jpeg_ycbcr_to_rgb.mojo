# IJG fixed-point color conversion; see benchmarks/m/mibench_jpeg_ycbcr_to_rgb/LICENSE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn jpeg_shift16(value: Int64) -> Int64:
    if value >= 0:
        return value // 65536
    return -((-value + 65535) // 65536)

fn jpeg_clamp(value: Int64) -> UInt8:
    if value < 0:
        return 0
    if value > 255:
        return 255
    return UInt8(value)

@export("mibench_jpeg_ycbcr_to_rgb")
fn mibench_jpeg_ycbcr_to_rgb(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 49:
        return -1
    let pixels = input[0]
    if pixels < 1 or pixels > 16 or length != c_size_t(1 + 3 * pixels):
        return -1
    var staged = InlineArray[UInt8, 48](fill=0)
    for i in range(Int(pixels)):
        let y = input[1 + 3 * i]
        let cb_sample = input[2 + 3 * i]
        let cr_sample = input[3 + 3 * i]
        if y < 0 or y > 255 or cb_sample < 0 or cb_sample > 255 or cr_sample < 0 or cr_sample > 255:
            return -1
        let cb = cb_sample - 128
        let cr = cr_sample - 128
        staged[3 * i] = jpeg_clamp(y + jpeg_shift16(91881 * cr + 32768))
        staged[3 * i + 1] = jpeg_clamp(y + jpeg_shift16(-22554 * cb + 32768 - 46802 * cr))
        staged[3 * i + 2] = jpeg_clamp(y + jpeg_shift16(116130 * cb + 32768))
    let bytes = 3 * Int(pixels)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    for i in range(bytes):
        output[i] = staged[i]
    return Int64(bytes)
