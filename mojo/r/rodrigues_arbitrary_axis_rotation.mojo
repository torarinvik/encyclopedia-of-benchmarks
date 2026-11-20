from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import abs, cos, isfinite, sin, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias COMPONENT_LIMIT = 1_000_000.0
alias ANGLE_LIMIT = 6.283185307179586
alias OUTPUT_LIMIT = 2_000_000.0

@export("rodrigues_arbitrary_axis_rotation")
fn rodrigues_arbitrary_axis_rotation(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 7:
        return -1
    for i in range(6):
        if not isfinite(input[i]) or abs(input[i]) > COMPONENT_LIMIT:
            return -1
    let theta = input[6]
    if not isfinite(theta) or abs(theta) > ANGLE_LIMIT:
        return -1

    var scale = abs(input[0])
    if abs(input[1]) > scale: scale = abs(input[1])
    if abs(input[2]) > scale: scale = abs(input[2])
    if scale == 0.0:
        return -1
    let qx = input[0] / scale
    let qy = input[1] / scale
    let qz = input[2] / scale
    let norm = sqrt((qx * qx + qy * qy) + qz * qz)
    if not isfinite(norm) or norm == 0.0:
        return -1
    let nx = qx / norm
    let ny = qy / norm
    let nz = qz / norm
    let vx = input[3]
    let vy = input[4]
    let vz = input[5]
    let cosine = cos(theta)
    let sine = sin(theta)
    let one_minus_cosine = 1.0 - cosine
    let cx = ny * vz - nz * vy
    let cy = nz * vx - nx * vz
    let cz = nx * vy - ny * vx
    let dot = (nx * vx + ny * vy) + nz * vz
    var result = InlineArray[Float64, 3](fill=0.0)
    result[0] = (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine
    result[1] = (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine
    result[2] = (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine
    for i in range(3):
        if not isfinite(result[i]) or abs(result[i]) > OUTPUT_LIMIT:
            return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 3:
        return -2
    for i in range(3):
        output[i] = result[i]
    return 3
