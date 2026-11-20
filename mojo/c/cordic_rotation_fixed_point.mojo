from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime OUTPUT_BYTES = 24
comptime SCALE = Int64(1_000_000_000)
comptime HALF_PI = Int64(1_570_796_327)

fn cordic_angle(shift: Int) -> Int64:
    if shift == 0: return 785_398_163
    if shift == 1: return 463_647_609
    if shift == 2: return 244_978_663
    if shift == 3: return 124_354_995
    if shift == 4: return 62_418_810
    if shift == 5: return 31_239_833
    if shift == 6: return 15_623_729
    if shift == 7: return 7_812_341
    if shift == 8: return 3_906_230
    if shift == 9: return 1_953_123
    if shift == 10: return 976_562
    if shift == 11: return 488_281
    if shift == 12: return 244_141
    if shift == 13: return 122_070
    return 61_035

fn cordic_shift_floor(value: Int64, shift: Int) -> Int64:
    if shift == 0: return value
    let divisor = Int64(1) << shift
    if value >= 0: return value / divisor
    return -((-value + divisor - 1) / divisor)

fn cordic_put_f64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Float64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("cordic_rotation_fixed_point")
fn cordic_rotation_fixed_point(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 3: return -1
    if length != 2: return -1
    let angle = input[0]
    let stages = input[1]
    if angle < -3_141_592_653 or angle > 3_141_592_653 or stages < 1 or stages > 16: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < OUTPUT_BYTES: return -2

    var x = SCALE
    var y = Int64(0)
    var z = angle
    var direction = Int64(1) if z >= 0 else Int64(-1)
    if direction > 0:
        let old_x = x
        x = -y
        y = old_x
    else:
        let old_x = x
        x = y
        y = -old_x
    z -= direction * HALF_PI
    for shift in range(Int(stages - 1)):
        direction = Int64(1) if z >= 0 else Int64(-1)
        let old_x = x
        let old_y = y
        x = old_x - direction * cordic_shift_floor(old_y, shift)
        y = old_y + direction * cordic_shift_floor(old_x, shift)
        z -= direction * cordic_angle(shift)

    let scale = Float64(1_000_000_000)
    cordic_put_f64(output, 0, Float64(x) / scale)
    cordic_put_f64(output, 8, Float64(y) / scale)
    cordic_put_f64(output, 16, Float64(z) / scale)
    return OUTPUT_BYTES
