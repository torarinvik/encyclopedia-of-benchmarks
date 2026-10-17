package rotation_matrix

import "core:c"
import "core:math"

MAX_ANGLE :: 1000.0

@(export)
rotation_matrix :: proc "c" (input: [^]f64, input_len: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_len != 1 do return -1
	theta := input[0]
	if theta != theta || theta < -MAX_ANGLE || theta > MAX_ANGLE do return -1
	cosine := math.cos(theta)
	sine := math.sin(theta)
	matrix := [4]f64{cosine, -sine, sine, cosine}
	if output == nil || output_capacity < 4 do return -2
	for index in 0..<4 { output[index] = matrix[index] }
	return 4
}
