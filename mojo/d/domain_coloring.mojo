from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dc_phase_hue(real_part: Int64, imaginary_part: Int64) -> Int64:
    if real_part == 0 and imaginary_part == 0: return 0
    let abs_real = if real_part < 0: -real_part else: real_part
    let abs_imaginary = if imaginary_part < 0: -imaginary_part else: imaginary_part
    let high = if abs_real > abs_imaginary: abs_real else: abs_imaginary
    let low = if abs_real < abs_imaginary: abs_real else: abs_imaginary
    let step = 192 * low // high
    var hue: Int64 = 0
    if imaginary_part >= 0:
        if real_part >= 0:
            hue = if abs_real >= abs_imaginary: step else: 384 - step
        else:
            hue = if abs_real < abs_imaginary: 384 + step else: 768 - step
    elif real_part < 0:
        hue = if abs_real >= abs_imaginary: 768 + step else: 1152 - step
    else:
        hue = if abs_real < abs_imaginary: 1152 + step else: 1536 - step
    return if hue == 1536: 0 else: hue

fn dc_store_pixel(inout pixels: InlineArray[UInt8, 768], offset: Int,
                  hue: Int64, magnitude16: Int64):
    let value = 128 + 8 * (magnitude16 % 16)
    let sector = hue // 256
    let fraction = hue % 256
    let rising = UInt8(value * fraction // 255)
    let falling = UInt8(value * (255 - fraction) // 255)
    let bright = UInt8(value)
    var red: UInt8 = 0
    var green: UInt8 = 0
    var blue: UInt8 = 0
    if sector == 0:
        red = bright; green = rising
    elif sector == 1:
        red = falling; green = bright
    elif sector == 2:
        green = bright; blue = rising
    elif sector == 3:
        green = falling; blue = bright
    elif sector == 4:
        red = rising; blue = bright
    else:
        red = bright; blue = falling
    pixels[offset] = red
    pixels[offset + 1] = green
    pixels[offset + 2] = blue

@export("domain_coloring")
fn domain_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t)
                   abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1
    let width_value = input[0]
    let height_value = input[1]
    let x_start = input[2]
    let y_start = input[3]
    let x_step = input[4]
    let y_step = input[5]
    if width_value < 1 or width_value > 16 or height_value < 1 or height_value > 16 or
        x_start < -32 or x_start > 32 or y_start < -32 or y_start > 32 or
        x_step < -8 or x_step > 8 or y_step < -8 or y_step > 8: return -1
    let x_end = x_start + (width_value - 1) * x_step
    let y_end = y_start + (height_value - 1) * y_step
    if x_end < -32 or x_end > 32 or y_end < -32 or y_end > 32: return -1

    let width = Int(width_value)
    let height = Int(height_value)
    let byte_count = 3 * width * height
    var rendered = InlineArray[UInt8, 768]()
    var offset = 0
    for row in range(height):
        let y_q = y_start + Int64(row) * y_step
        for column in range(width):
            let x_q = x_start + Int64(column) * x_step
            let x_squared = x_q * x_q
            let y_squared = y_q * y_q
            dc_store_pixel(rendered, offset,
                dc_phase_hue(x_squared - y_squared, 2 * x_q * y_q),
                x_squared + y_squared)
            offset += 3
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for index in range(byte_count): output[index] = rendered[index]
    return Int64(byte_count)
