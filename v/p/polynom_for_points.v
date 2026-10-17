module polynom_for_points

import math

const min_points = 2
const max_points = 8
const min_x = i64(-4)
const max_x = i64(4)
const min_y = i64(-25000)
const max_y = i64(25000)
const max_coefficient = f64(1000000.0)
const max_contract_bytes = 124
const scratch_bytes = 125

fn append_text(mut buffer [scratch_bytes]u8, mut position int, text string) {
	for index in 0 .. text.len {
		buffer[position] = text[index]
		position++
	}
}

fn append_i64(mut buffer [scratch_bytes]u8, mut position int, value_value i64) {
	mut value := value_value
	mut digits := [24]u8{}
	mut count := 0
	if value < 0 { buffer[position] = `-`; position++; value = -value }
	for {
		digits[count] = u8(value % 10) + `0`
		count++
		value /= 10
		if value == 0 { break }
	}
	for count > 0 {
		count--
		buffer[position] = digits[count]
		position++
	}
}

fn append_coefficient(mut buffer [scratch_bytes]u8, mut position int, value f64) {
	if value == 0.0 {
		if u64(math.bits_from_f64(value)) >> 63 != 0 { buffer[position] = `-`; position++ }
		append_text(mut buffer, mut position, "0.0")
		return
	}
	append_i64(mut buffer, mut position, i64(value))
	append_text(mut buffer, mut position, ".0")
}

@[export: 'polynom_for_points']
pub fn polynom_for_points(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if isnil(values) || length < 1 || length > 1 + 2 * max_points { return -1 }
		raw_n := values[0]
		if raw_n < min_points || raw_n > max_points || length != usize(1 + 2 * raw_n) { return -1 }
		n := int(raw_n)
		mut xs := [max_points]i64{}
		mut matrix := [max_points][max_points]f64{}
		mut vector := [max_points]f64{}
		for row in 0 .. n {
			x := values[1 + 2 * row]
			y := values[2 + 2 * row]
			if x < min_x || x > max_x || y < min_y || y > max_y { return -1 }
			for previous in 0 .. row { if xs[previous] == x { return -1 } }
			xs[row] = x
			for column in 0 .. n {
				mut power := i64(1)
				for _ in 0 .. (n - column - 1) { power *= x }
				matrix[row][column] = f64(power)
			}
			vector[row] = f64(y)
		}

		for count in 0 .. n {
			if matrix[count][count] == 0.0 {
				mut pivot_row := count + 1
				for row in count + 2 .. n {
					if math.abs(matrix[row][count]) > math.abs(matrix[pivot_row][count]) { pivot_row = row }
				}
				if pivot_row >= n || matrix[pivot_row][count] == 0.0 { return -1 }
				for column in 0 .. n {
					temporary := matrix[count][column]
					matrix[count][column] = matrix[pivot_row][column]
					matrix[pivot_row][column] = temporary
				}
				temporary := vector[count]
				vector[count] = vector[pivot_row]
				vector[pivot_row] = temporary
			}
			for row in 0 .. n {
				if row == count { continue }
				fraction := matrix[row][count] / matrix[count][count]
				for column in 0 .. n {
					product := matrix[count][column] * fraction
					matrix[row][column] = matrix[row][column] - product
				}
				product := vector[count] * fraction
				vector[row] = vector[row] - product
			}
		}

		mut coefficients := [max_points]f64{}
		for index in 0 .. n {
			value := vector[index] / matrix[index][index]
			if math.is_nan(value) || math.is_inf(value) || math.abs(value) > max_coefficient || f64(i64(value)) != value { return -1 }
			coefficients[index] = value
		}

		mut buffer := [scratch_bytes]u8{}
		mut position := 0
		append_text(mut buffer, mut position, "f(x)=")
		for index in 0 .. n {
			if index != 0 { buffer[position] = `+`; position++ }
			append_text(mut buffer, mut position, "x^")
			append_i64(mut buffer, mut position, i64(n - index - 1))
			buffer[position] = `*`; position++
			append_coefficient(mut buffer, mut position, coefficients[index])
		}
		if position > max_contract_bytes { return -1 }
		if isnil(output) || output_capacity < usize(position) { return -2 }
		for index in 0 .. position { output[index] = buffer[index] }
		return i64(position)
	}
}
