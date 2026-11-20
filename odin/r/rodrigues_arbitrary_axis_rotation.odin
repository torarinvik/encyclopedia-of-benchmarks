package rodrigues_arbitrary_axis_rotation

import "core:c"
import "core:math"

COMPONENT_LIMIT :: 1_000_000.0
ANGLE_LIMIT :: 6.283185307179586
OUTPUT_LIMIT :: 2_000_000.0

@(export)
rodrigues_arbitrary_axis_rotation :: proc "c" (input: [^]f64, input_len: c.size_t,
        output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_len != 7 do return -1
    for i in 0..<6 {
        value := input[i]
        if value != value || value < -COMPONENT_LIMIT || value > COMPONENT_LIMIT do return -1
    }
    theta := input[6]
    if theta != theta || theta < -ANGLE_LIMIT || theta > ANGLE_LIMIT do return -1
    scale := math.abs(input[0])
    if math.abs(input[1]) > scale do scale = math.abs(input[1])
    if math.abs(input[2]) > scale do scale = math.abs(input[2])
    if scale == 0.0 do return -1
    qx, qy, qz := input[0]/scale, input[1]/scale, input[2]/scale
    norm := math.sqrt((qx*qx + qy*qy) + qz*qz)
    if norm != norm || norm == 0.0 do return -1
    nx, ny, nz := qx/norm, qy/norm, qz/norm
    vx, vy, vz := input[3], input[4], input[5]
    cosine, sine := math.cos(theta), math.sin(theta)
    one_minus_cosine := 1.0 - cosine
    cx := ny*vz - nz*vy
    cy := nz*vx - nx*vz
    cz := nx*vy - ny*vx
    dot := (nx*vx + ny*vy) + nz*vz
    result := [3]f64{
        (vx*cosine + cx*sine) + (nx*dot)*one_minus_cosine,
        (vy*cosine + cy*sine) + (ny*dot)*one_minus_cosine,
        (vz*cosine + cz*sine) + (nz*dot)*one_minus_cosine,
    }
    for i in 0..<3 {
        value := result[i]
        if value != value || value < -OUTPUT_LIMIT || value > OUTPUT_LIMIT do return -1
    }
    if output == nil || output_capacity < 3 do return -2
    for i in 0..<3 { output[i] = result[i] }
    return 3
}
