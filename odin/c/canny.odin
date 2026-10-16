package canny

import "core:c"

MAX_SIDE :: 16
MAX_PIXELS :: MAX_SIDE * MAX_SIDE
NORM_SCALE :: i64(1_048_576)
ANGLE_SCALE :: i64(1_000_000_000)
TAN_22_5_Q9 :: i64(414_213_562)
GAUSSIAN :: [25]i64{
	85_321, 66_110, 30_754, 8_589, 1_440,
	66_110, 51_225, 23_829, 6_655, 1_116,
	30_754, 23_829, 11_085, 3_096, 519,
	8_589, 6_655, 3_096, 865, 145,
	1_440, 1_116, 519, 145, 24,
}
SOBEL_X :: [9]i64{-1, 0, 1, -2, 0, 2, -1, 0, 1}
SOBEL_Y :: [9]i64{1, 2, 1, 0, 0, 0, -1, -2, -1}

canny_clamp :: proc "contextless" (coordinate: i64, side: int) -> int {
	if coordinate < 0 do return 0
	if coordinate >= i64(side) do return side - 1
	return int(coordinate)
}

canny_isqrt :: proc "contextless" (value: u64) -> u64 {
	if value < 2 do return value
	low := u64(1)
	high := min(value, u64(4_294_967_296))
	for low <= high {
		middle := low + (high - low) / 2
		if middle <= value / middle {
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return high
}

@(export)
canny :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	blurred: [MAX_PIXELS]i64
	gradient_x: [MAX_PIXELS]i64
	gradient_y: [MAX_PIXELS]i64
	normalized_x: [MAX_PIXELS]i64
	normalized_y: [MAX_PIXELS]i64
	magnitude: [MAX_PIXELS]i64
	destination: [MAX_PIXELS]i64
	gaussian := GAUSSIAN
	sobel_x := SOBEL_X
	sobel_y := SOBEL_Y

	if values == nil || length < 2 || length > 1 + MAX_PIXELS { return -1 }
	side_value := values[0]
	if side_value < 1 || side_value > MAX_SIDE { return -1 }
	side := int(side_value)
	pixels := side * side
	if length != c.size_t(pixels + 1) { return -1 }
	for index := 0; index < pixels; index += 1 {
		if values[index + 1] < 0 || values[index + 1] > 255 { return -1 }
	}
	if output_capacity < c.size_t(pixels) || output == nil { return -2 }

	for row in 0..<side {
		for column in 0..<side {
			total := i64(0)
			for ky := -4; ky <= 4; ky += 1 {
				source_row := canny_clamp(i64(row + ky), side)
				for kx := -4; kx <= 4; kx += 1 {
					source_column := canny_clamp(i64(column + kx), side)
					ay := ky
					if ay < 0 do ay = -ay
					ax := kx
					if ax < 0 do ax = -ax
				total += gaussian[ay * 5 + ax] * values[1 + source_row * side + source_column]
				}
			}
			blurred[row * side + column] = total
		}
	}

	maximum_x := i64(0)
	maximum_y := i64(0)
	for row in 0..<side {
		for column in 0..<side {
			total_x := i64(0)
			total_y := i64(0)
			for ky := -1; ky <= 1; ky += 1 {
				source_row := canny_clamp(i64(row + ky), side)
				for kx := -1; kx <= 1; kx += 1 {
					source_column := canny_clamp(i64(column + kx), side)
					sample := blurred[source_row * side + source_column]
					kernel_index := (ky + 1) * 3 + kx + 1
					total_x += sample * sobel_x[kernel_index]
					total_y += sample * sobel_y[kernel_index]
				}
			}
			if total_x < 0 do total_x = -total_x
			if total_y < 0 do total_y = -total_y
			offset := row * side + column
			gradient_x[offset] = total_x
			gradient_y[offset] = total_y
			maximum_x = max(maximum_x, total_x)
			maximum_y = max(maximum_y, total_y)
		}
	}

	maximum_magnitude := u64(0)
	for index in 0..<pixels {
		if maximum_x != 0 do normalized_x[index] = gradient_x[index] * 255 * NORM_SCALE / maximum_x
		if maximum_y != 0 do normalized_y[index] = gradient_y[index] * 255 * NORM_SCALE / maximum_y
		x := u64(normalized_x[index])
		y := u64(normalized_y[index])
		magnitude[index] = i64(canny_isqrt(x*x + y*y))
		maximum_magnitude = max(maximum_magnitude, u64(magnitude[index]))
	}
	if maximum_magnitude != 0 {
		for index in 0..<pixels { magnitude[index] = magnitude[index] * 255 / i64(maximum_magnitude) }
	}

	for row := 1; row+1 < side; row += 1 {
		for column := 1; column+1 < side; column += 1 {
			offset := row * side + column
			before := offset - 1
			after := offset + 1
			if normalized_y[offset] * ANGLE_SCALE >= normalized_x[offset] * TAN_22_5_Q9 {
				if normalized_x[offset] * ANGLE_SCALE <= normalized_y[offset] * TAN_22_5_Q9 {
					before = offset - side
					after = offset + side
				} else {
					before = offset + side - 1
					after = offset - side + 1
				}
			}
			if magnitude[offset] >= magnitude[before] && magnitude[offset] >= magnitude[after] do destination[offset] = magnitude[offset]
		}
	}
	for index in 0..<pixels {
		if destination[index] >= 30 {
			destination[index] = 255
		} else if destination[index] <= 15 {
			destination[index] = 0
		} else {
			destination[index] = 128
		}
	}
	for row := 1; row+1 < side; row += 1 {
		for column := 1; column+1 < side; column += 1 {
			offset := row * side + column
			if destination[offset] == 128 {
				connected := false
				for dy := -1; dy <= 1; dy += 1 {
					for dx := -1; dx <= 1; dx += 1 {
						neighbor := (row + dy) * side + column + dx
						if (dx != 0 || dy != 0) && destination[neighbor] == 255 do connected = true
					}
				}
				destination[offset] = 0
				if connected do destination[offset] = 255
			}
		}
	}
	for index in 0..<pixels { output[index] = u8(destination[index]) }
	return i64(pixels)
}
