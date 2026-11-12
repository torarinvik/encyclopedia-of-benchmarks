package splash2_fft_six_step

import "core:c"
import "core:math"

MAX_OUTPUT :: 128
TAU :: 6.283185307179586476925286766559

transpose :: proc(source, destination: [^]f64, side: int) {
	for row in 0..<side {
		for column in 0..<side {
			from := 2 * (row * side + column)
			to := 2 * (column * side + row)
			destination[to] = source[from]
			destination[to+1] = source[from+1]
		}
	}
}

fft_row :: proc(data: [^]f64, base, side: int) {
	reverse := 0
	for position in 1..<side {
		bit := side >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			left, right := 2*(base+position), 2*(base+reverse)
			temporary := data[left]; data[left] = data[right]; data[right] = temporary
			temporary = data[left+1]; data[left+1] = data[right+1]; data[right+1] = temporary
		}
	}
	block := 2
	for block <= side {
		half := block / 2
		angle_step := TAU / f64(block)
		for start := 0; start < side; start += block {
			for offset in 0..<half {
				angle := angle_step * f64(offset)
				weight_real, weight_imag := math.cos_f64(angle), -math.sin_f64(angle)
				first := 2*(base+start+offset)
				second := 2*(base+start+offset+half)
				product_real := weight_real*data[second] - weight_imag*data[second+1]
				product_imag := weight_real*data[second+1] + weight_imag*data[second]
				first_real, first_imag := data[first], data[first+1]
				data[first] = first_real + product_real
				data[first+1] = first_imag + product_imag
				data[second] = first_real - product_real
				data[second+1] = first_imag - product_imag
			}
		}
		block *= 2
	}
}

@(export)
splash2_fft_six_step :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 9 || input_length > 130 do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	side_value := input[0]
	if side_value != 2 && side_value != 4 && side_value != 8 do return -1
	side := int(side_value)
	points := side * side
	if input_length != c.size_t(1+2*points) do return -1
	for i in 0..<2*points {
		if input[i+1] < -8 || input[i+1] > 8 do return -1
	}

	first_matrix: [MAX_OUTPUT]f64
	second_matrix: [MAX_OUTPUT]f64
	for i in 0..<2*points { first_matrix[i] = input[i+1] }
	transpose(&first_matrix[0], &second_matrix[0], side)
	for row in 0..<side { fft_row(&second_matrix[0], row*side, side) }
	for row in 0..<side {
		for column in 0..<side {
			index := 2*(row*side+column)
			angle := TAU*f64(row*column)/f64(points)
			cosine, sine := math.cos_f64(angle), math.sin_f64(angle)
			real, imag := second_matrix[index], second_matrix[index+1]
			second_matrix[index] = cosine*real + sine*imag
			second_matrix[index+1] = cosine*imag - sine*real
		}
	}
	transpose(&second_matrix[0], &first_matrix[0], side)
	for row in 0..<side { fft_row(&first_matrix[0], row*side, side) }
	transpose(&first_matrix[0], &second_matrix[0], side)

	needed := 2*points
	if output == nil || output_capacity < c.size_t(needed) do return -2
	for i in 0..<needed { output[i] = second_matrix[i] }
	return i64(needed)
}
