from std.ffi import c_size_t
from std.math import pow
from std.memory import ImmutAnyOrigin, UnsafePointer

fn contrast_component(channel: Int64) -> Float64:
    let srgb = Float64(channel) / 255.0
    if srgb <= 0.03928: return srgb / 12.92
    let adjusted = (srgb + 0.055) / 1.055
    return pow(adjusted, 2.4)

fn contrast_luminance(r: Int64, g: Int64, b: Int64) -> Float64:
    return 0.2126 * contrast_component(r) + 0.7152 * contrast_component(g) + 0.0722 * contrast_component(b)

@export("color_contrast_ratio")
fn color_contrast_ratio(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1.0e300
    for i in range(6):
        if values[i] < 0 or values[i] > 255: return -1.0e300
    let first = contrast_luminance(values[0], values[1], values[2])
    let second = contrast_luminance(values[3], values[4], values[5])
    if first > second: return (first + 0.05) / (second + 0.05)
    return (second + 0.05) / (first + 0.05)
