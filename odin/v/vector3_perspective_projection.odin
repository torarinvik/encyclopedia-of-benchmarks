package vector3_perspective_projection

import "core:c"
import "core:math"

INPUT_LIMIT :: 1_000_000.0
DENOMINATOR_FLOOR :: 0.000001
OUTPUT_LIMIT :: 1.0e25

@(export)
vector3_perspective_projection :: proc "c" (input: [^]f64, input_len: c.size_t,
                                                output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_len != 5 do return -1
    for i in 0..<5 {
        value := input[i]
        if value != value || value < -INPUT_LIMIT || value > INPUT_LIMIT do return -1
    }
    denominator := input[2] + input[4]
    if denominator > -DENOMINATOR_FLOOR && denominator < DENOMINATOR_FLOOR do return -1
    x := ((input[0] * input[4]) / denominator) * input[3]
    y := ((input[1] * input[4]) / denominator) * input[3]
    if x != x || y != y || x < -OUTPUT_LIMIT || x > OUTPUT_LIMIT ||
        y < -OUTPUT_LIMIT || y > OUTPUT_LIMIT do return -1
    if output == nil || output_capacity < 2 do return -2
    output[0] = x
    output[1] = y
    return 2
}
