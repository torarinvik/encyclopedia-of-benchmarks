from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn truncate_divide(numerator: Int64, denominator: Int64) -> Int64:
    if numerator < 0: return -((-numerator) // denominator)
    return numerator // denominator

@export("change_contrast")
fn change_contrast(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4096: return -1
    let level = values[0]
    if level < -255 or level > 255: return -1
    let channels = length - 1
    for i in range(channels):
        if values[i + 1] < 0 or values[i + 1] > 255: return -1
    if channels > output_capacity or (channels != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    let denominator = 255 * (259 - level)
    var staged = InlineArray[UInt8, 4095](0)
    for i in range(channels):
        let channel = values[i + 1]
        let numerator = 128 * denominator + 259 * (level + 255) * (channel - 128)
        var value = truncate_divide(numerator, denominator)
        if value < 0: value = 0
        if value > 255: value = 255
        staged[i] = UInt8(value)
    for i in range(channels): output[i] = staged[i]
    return Int64(channels)
