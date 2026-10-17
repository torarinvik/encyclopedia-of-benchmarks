module rotation_matrix

import math

const max_angle = 1000.0

pub fn rotation_matrix(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_len != 1 { return -1 }
	unsafe {
		theta := input[0]
		if !theta.is_finite() || theta < -max_angle || theta > max_angle { return -1 }
		cosine := math.cos(theta)
		sine := math.sin(theta)
		matrix := [4]f64{cosine, -sine, sine, cosine}
		if output == nil || output_capacity < 4 { return -2 }
		for index in 0 .. 4 { output[index] = matrix[index] }
		return 4
	}
}
