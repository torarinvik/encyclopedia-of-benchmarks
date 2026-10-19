from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("comp_filt")
fn comp_filt(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 68: return -1.0e300
    let alpha_ppm = values[0]
    let dt_micro = values[1]
    let count = values[2]
    let output_index = values[3]
    if alpha_ppm < 0 or alpha_ppm > 1000000 or dt_micro < 0 or dt_micro > 1000000 or count < 1 or count > 32 or output_index < 0 or output_index > count or length != 4 + 2 * count: return -1.0e300
    for i in range(count):
        if values[4 + i] < -1000000 or values[4 + i] > 1000000 or values[4 + count + i] < -1000000 or values[4 + count + i] > 1000000: return -1.0e300
    let alpha = Float64(alpha_ppm) / 1000000.0
    let dt = Float64(dt_micro) / 1000000.0
    var theta = Float64(values[4 + count]) / 1000000.0
    for i in range(output_index):
        let rate = Float64(values[4 + i]) / 1000000.0
        let reference = Float64(values[4 + count + i]) / 1000000.0
        theta = alpha * (theta + rate * dt) + (1.0 - alpha) * reference
    return theta
