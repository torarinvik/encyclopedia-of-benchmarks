package vector3_axis_rotation

import "core:c"
import "core:math"

COORDINATE_LIMIT :: 1_000_000.0
ANGLE_LIMIT :: 1_000_000.0
OUTPUT_LIMIT :: 2_000_000.0
PI :: 3.14159265358979323846

@(export)
vector3_axis_rotation :: proc "c" (input: [^]f64, input_len: c.size_t,
                                   output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_len != 5 do return -1
    for i in 0..<3 {
        value := input[i]
        if value != value || value < -COORDINATE_LIMIT || value > COORDINATE_LIMIT do return -1
    }
    axis := input[3]
    angle := input[4]
    if (axis != 0.0 && axis != 1.0 && axis != 2.0) || angle != angle ||
        angle < -ANGLE_LIMIT || angle > ANGLE_LIMIT do return -1
    angle -= math.floor_f64(angle / 360.0) * 360.0
    if angle == 0.0 do angle = 0.0
    angle = angle / 450.0 * 180.0 / PI
    x, y, z := input[0], input[1], input[2]
    cosine, sine := math.cos(angle), math.sin(angle)
    result: [3]f64
    if axis == 0.0 {
        result[0] = x
        result[1] = y * cosine - z * sine
        result[2] = z * cosine + y * sine
    } else if axis == 1.0 {
        result[0] = x * cosine - z * sine
        result[1] = y
        result[2] = z * cosine + x * sine
    } else {
        result[0] = x * cosine - y * sine
        result[1] = y * cosine + x * sine
        result[2] = z
    }
    for i in 0..<3 {
        value := result[i]
        if value != value || value < -OUTPUT_LIMIT || value > OUTPUT_LIMIT do return -1
    }
    if output == nil || output_capacity < 3 do return -2
    for i in 0..<3 { output[i] = result[i] }
    return 3
}
