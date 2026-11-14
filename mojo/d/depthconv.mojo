# Independent bounded depthwise convolution; see package NOTICE.txt and LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("depthconv")
fn depthconv(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 89: return -1
    let channels = input[0]
    if channels < 1 or channels > 8 or length != c_size_t(1 + 11 * channels): return -1
    let c = Int(channels)
    var values = InlineArray[Int64, 88](fill=0)
    for i in range(11 * c): values[i] = input[1 + i]
    for i in range(8 * c):
        if values[i] < -128 or values[i] > 127: return -1
    for i in range(c):
        if values[8 * c + i] < -1000000 or values[8 * c + i] > 1000000: return -1
        if values[9 * c + i] < 0 or values[9 * c + i] > 2147483647: return -1
        if values[10 * c + i] < -8 or values[10 * c + i] > 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(c): return -2
    for channel in range(c):
        var acc: Int64 = 0
        for row in range(4):
            acc += values[4 * c + row * c + channel] * (values[row * c + channel] + 128)
        acc += values[8 * c + channel]
        let shift = Int(31 - values[10 * c + channel])
        let divisor = Int64(1) << shift
        let product = acc * values[9 * c + channel] + (divisor >> 1)
        var scaled = if product >= 0: product // divisor else: -((-product + divisor - 1) // divisor)
        scaled = min(127, max(-128, scaled))
        output[channel] = UInt8(bitcast[UInt64](scaled) & 255)
    return Int64(c)
