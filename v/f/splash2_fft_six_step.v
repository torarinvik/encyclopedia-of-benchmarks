import math

const max_output = 128
const tau = 6.283185307179586476925286766559

fn transpose(mut source [max_output]f64, mut destination [max_output]f64, side int) {
	for row in 0 .. side {
		for column in 0 .. side {
			from := 2 * (row * side + column)
			to := 2 * (column * side + row)
			destination[to] = source[from]
			destination[to + 1] = source[from + 1]
		}
	}
}


fn fft_row(mut data [max_output]f64, base int, side int) {
	mut reverse := 0
	for position in 1 .. side {
		mut bit := side >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			left := 2 * (base + position)
			right := 2 * (base + reverse)
			temporary := data[left]
			data[left] = data[right]
			data[right] = temporary
			temporary = data[left + 1]
			data[left + 1] = data[right + 1]
			data[right + 1] = temporary
		}
	}
	mut block := 2
	for block <= side {
		half := block / 2
		angle_step := tau / f64(block)
		mut start := 0
		for start < side {
			for offset in 0 .. half {
				angle := angle_step * f64(offset)
				weight_real := math.cos(angle)
				weight_imag := -math.sin(angle)
				first := 2 * (base + start + offset)
				second := 2 * (base + start + offset + half)
				product_real := weight_real * data[second] - weight_imag * data[second + 1]
				product_imag := weight_real * data[second + 1] + weight_imag * data[second]
				first_real := data[first]
				first_imag := data[first + 1]
				data[first] = first_real + product_real
				data[first + 1] = first_imag + product_imag
				data[second] = first_real - product_real
				data[second + 1] = first_imag - product_imag
			}
			start += block
		}
		block *= 2
	}
}

@[export: 'splash2_fft_six_step']
pub fn splash2_fft_six_step(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 9 || input_length > 130 { return -1 }
		for i in 0 .. input_length { if !math.is_finite(input[i]) { return -1 } }
		side_value := input[0]
		if side_value != 2.0 && side_value != 4.0 && side_value != 8.0 { return -1 }
		side := int(side_value)
		points := side * side
		if input_length != usize(1 + 2 * points) { return -1 }
		for i in 0 .. 2 * points {
			if input[i + 1] < -8.0 || input[i + 1] > 8.0 { return -1 }
		}
		mut first_matrix := [max_output]f64{}
		mut second_matrix := [max_output]f64{}
		for i in 0 .. 2 * points { first_matrix[i] = input[i + 1] }
		transpose(mut first_matrix, mut second_matrix, side)
		for row in 0 .. side { fft_row(mut second_matrix, row * side, side) }
		for row in 0 .. side {
			for column in 0 .. side {
				index := 2 * (row * side + column)
				angle := tau * f64(row * column) / f64(points)
				cosine := math.cos(angle)
				sine := math.sin(angle)
				real := second_matrix[index]
				imag := second_matrix[index + 1]
				second_matrix[index] = cosine * real + sine * imag
				second_matrix[index + 1] = cosine * imag - sine * real
			}
		}
		transpose(mut second_matrix, mut first_matrix, side)
		for row in 0 .. side { fft_row(mut first_matrix, row * side, side) }
		transpose(mut first_matrix, mut second_matrix, side)
		needed := 2 * points
		if output == nil || output_capacity < usize(needed) { return -2 }
		for i in 0 .. needed { output[i] = second_matrix[i] }
		return i64(needed)
	}
}
