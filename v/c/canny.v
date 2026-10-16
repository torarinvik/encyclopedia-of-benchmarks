module canny

const max_side = 16
const max_pixels = max_side * max_side

@[export: 'canny']
pub fn canny(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 1 + max_pixels { return -1 }
	if unsafe { values == nil } { return -1 }
	side_value := unsafe { values[0] }
	if side_value < 1 || side_value > max_side { return -1 }
	side := int(side_value)
	pixels := side * side
	norm_scale := i64(1_048_576)
	angle_scale := i64(1_000_000_000)
	tan_22_5_q9 := i64(414_213_562)
	if length != usize(pixels + 1) { return -1 }
	unsafe {
		for index in 0 .. pixels {
			if values[index + 1] < 0 || values[index + 1] > 255 { return -1 }
		}
	}
	if output_capacity < usize(pixels) || unsafe { output == nil } { return -2 }

	mut gaussian_weights := [25]i64{init: 0}
	gaussian_weights[0] = 85_321
	gaussian_weights[1] = 66_110
	gaussian_weights[2] = 30_754
	gaussian_weights[3] = 8_589
	gaussian_weights[4] = 1_440
	gaussian_weights[5] = 66_110
	gaussian_weights[6] = 51_225
	gaussian_weights[7] = 23_829
	gaussian_weights[8] = 6_655
	gaussian_weights[9] = 1_116
	gaussian_weights[10] = 30_754
	gaussian_weights[11] = 23_829
	gaussian_weights[12] = 11_085
	gaussian_weights[13] = 3_096
	gaussian_weights[14] = 519
	gaussian_weights[15] = 8_589
	gaussian_weights[16] = 6_655
	gaussian_weights[17] = 3_096
	gaussian_weights[18] = 865
	gaussian_weights[19] = 145
	gaussian_weights[20] = 1_440
	gaussian_weights[21] = 1_116
	gaussian_weights[22] = 519
	gaussian_weights[23] = 145
	gaussian_weights[24] = 24
	mut sobel_x := [9]i64{init: 0}
	mut sobel_y := [9]i64{init: 0}
	sobel_x[0] = -1
	sobel_x[2] = 1
	sobel_x[3] = -2
	sobel_x[5] = 2
	sobel_x[6] = -1
	sobel_x[8] = 1
	sobel_y[0] = 1
	sobel_y[1] = 2
	sobel_y[2] = 1
	sobel_y[6] = -1
	sobel_y[7] = -2
	sobel_y[8] = -1
	mut blurred := [max_pixels]i64{init: 0}
	mut gradient_x := [max_pixels]i64{init: 0}
	mut gradient_y := [max_pixels]i64{init: 0}
	mut normalized_x := [max_pixels]i64{init: 0}
	mut normalized_y := [max_pixels]i64{init: 0}
	mut magnitude := [max_pixels]i64{init: 0}
	mut destination := [max_pixels]i64{init: 0}

	for row := 0; row < side; row++ {
		for column := 0; column < side; column++ {
			mut total := i64(0)
			for ky := -4; ky <= 4; ky++ {
				source_row_coordinate := row + ky
				source_row := if source_row_coordinate < 0 { 0 } else if source_row_coordinate >= side { side - 1 } else { source_row_coordinate }
				for kx := -4; kx <= 4; kx++ {
					source_column_coordinate := column + kx
					source_column := if source_column_coordinate < 0 { 0 } else if source_column_coordinate >= side { side - 1 } else { source_column_coordinate }
					ay := if ky < 0 { -ky } else { ky }
					ax := if kx < 0 { -kx } else { kx }
					unsafe {
						total += gaussian_weights[ay * 5 + ax] * values[1 + source_row * side + source_column]
					}
				}
			}
			blurred[row * side + column] = total
		}
	}

	mut maximum_x := i64(0)
	mut maximum_y := i64(0)
	for row := 0; row < side; row++ {
		for column := 0; column < side; column++ {
			mut total_x := i64(0)
			mut total_y := i64(0)
			for ky := -1; ky <= 1; ky++ {
				source_row_coordinate := row + ky
				source_row := if source_row_coordinate < 0 { 0 } else if source_row_coordinate >= side { side - 1 } else { source_row_coordinate }
				for kx := -1; kx <= 1; kx++ {
					source_column_coordinate := column + kx
					source_column := if source_column_coordinate < 0 { 0 } else if source_column_coordinate >= side { side - 1 } else { source_column_coordinate }
					sample := blurred[source_row * side + source_column]
					kernel_index := (ky + 1) * 3 + kx + 1
					total_x += sample * sobel_x[kernel_index]
					total_y += sample * sobel_y[kernel_index]
				}
			}
			if total_x < 0 { total_x = -total_x }
			if total_y < 0 { total_y = -total_y }
			offset := row * side + column
			gradient_x[offset] = total_x
			gradient_y[offset] = total_y
		}
	}
	for index := 0; index < pixels; index++ {
		if gradient_x[index] > maximum_x { maximum_x = gradient_x[index] }
		if gradient_y[index] > maximum_y { maximum_y = gradient_y[index] }
	}

	mut maximum_magnitude := u64(0)
	for index := 0; index < pixels; index++ {
		if maximum_x != 0 { normalized_x[index] = gradient_x[index] * 255 * norm_scale / maximum_x }
		if maximum_y != 0 { normalized_y[index] = gradient_y[index] * 255 * norm_scale / maximum_y }
		x := u64(normalized_x[index])
		y := u64(normalized_y[index])
		root_value := x * x + y * y
		mut root_low := u64(1)
		mut root_high := if root_value < 4_294_967_296 { root_value } else { u64(4_294_967_296) }
		if root_value < 2 {
			magnitude[index] = i64(root_value)
		} else {
			for root_low <= root_high {
				root_middle := root_low + (root_high - root_low) / 2
				if root_middle <= root_value / root_middle { root_low = root_middle + 1 } else { root_high = root_middle - 1 }
			}
			magnitude[index] = i64(root_high)
		}
		if u64(magnitude[index]) > maximum_magnitude { maximum_magnitude = u64(magnitude[index]) }
	}
	if maximum_magnitude != 0 {
		for index := 0; index < pixels; index++ { magnitude[index] = magnitude[index] * 255 / i64(maximum_magnitude) }
	}
	for row := 1; row + 1 < side; row++ {
		for column := 1; column + 1 < side; column++ {
			offset := row * side + column
			mut before := offset - 1
			mut after := offset + 1
			if normalized_y[offset] * angle_scale >= normalized_x[offset] * tan_22_5_q9 {
				if normalized_x[offset] * angle_scale <= normalized_y[offset] * tan_22_5_q9 {
					before = offset - side
					after = offset + side
				} else {
					before = offset + side - 1
					after = offset - side + 1
				}
			}
			if magnitude[offset] >= magnitude[before] && magnitude[offset] >= magnitude[after] {
				destination[offset] = magnitude[offset]
			}
		}
	}
	for index := 0; index < pixels; index++ {
		if destination[index] >= 30 { destination[index] = 255 }
		else if destination[index] <= 15 { destination[index] = 0 }
		else { destination[index] = 128 }
	}
	for row := 1; row + 1 < side; row++ {
		for column := 1; column + 1 < side; column++ {
			offset := row * side + column
			if destination[offset] == 128 {
				mut connected := false
				for dy := -1; dy <= 1; dy++ {
					for dx := -1; dx <= 1; dx++ {
						neighbor := (row + dy) * side + column + dx
						if (dx != 0 || dy != 0) && destination[neighbor] == 255 { connected = true }
					}
				}
				destination[offset] = if connected { 255 } else { 0 }
			}
		}
	}
	unsafe {
		for index := 0; index < pixels; index++ { output[index] = u8(destination[index]) }
	}
	return i64(pixels)
}
