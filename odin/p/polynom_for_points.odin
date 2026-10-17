package polynom_for_points

import "core:c"

MIN_POINTS :: 2
MAX_POINTS :: 8
MIN_X :: i64(-4)
MAX_X :: i64(4)
MIN_Y :: i64(-25000)
MAX_Y :: i64(25000)
MAX_COEFFICIENT :: f64(1000000.0)
MAX_CONTRACT_BYTES :: 124
SCRATCH_BYTES :: 125

absolute :: proc "contextless" (value: f64) -> f64 {
	return if value < 0.0 then -value else value
}

append_text :: proc "contextless" (buffer: [^]u8, position_value: int, text: string) -> int {
	position := position_value
	for index := 0; index < len(text); index += 1 {
		buffer[position] = text[index]
		position += 1
	}
	return position
}

append_i64 :: proc "contextless" (buffer: [^]u8, position_value: int, value_value: i64) -> int {
	position := position_value
	value := value_value
	digits: [24]u8
	count := 0
	if value < 0 { buffer[position] = u8('-'); position += 1; value = -value }
	for {
		digits[count] = u8(value % 10) + u8('0')
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[position] = digits[count]
		position += 1
	}
	return position
}

append_coefficient :: proc "contextless" (buffer: [^]u8, position_value: int, value: f64) -> int {
	position := position_value
	if value == 0.0 {
		bits := transmute(u64)value
		if bits >> 63 != 0 { buffer[position] = u8('-'); position += 1 }
		return append_text(buffer, position, "0.0")
	}
	position = append_i64(buffer, position, i64(value))
	return append_text(buffer, position, ".0")
}

@(export)
polynom_for_points :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 1 + 2 * MAX_POINTS do return -1
	raw_n := values[0]
	if raw_n < MIN_POINTS || raw_n > MAX_POINTS || length != c.size_t(1 + 2 * raw_n) do return -1
	n := int(raw_n)
	var xs: [MAX_POINTS]i64
	var matrix: [MAX_POINTS][MAX_POINTS]f64 = {}
	var vector: [MAX_POINTS]f64 = {}
	for row := 0; row < n; row += 1 {
		x := values[1 + 2 * row]
		y := values[2 + 2 * row]
		if x < MIN_X || x > MAX_X || y < MIN_Y || y > MAX_Y do return -1
		for previous := 0; previous < row; previous += 1 { if xs[previous] == x do return -1 }
		xs[row] = x
		for column := 0; column < n; column += 1 {
			power := i64(1)
			for step := 0; step < n-column-1; step += 1 { power *= x }
			matrix[row][column] = f64(power)
		}
		vector[row] = f64(y)
	}

	for count := 0; count < n; count += 1 {
		if matrix[count][count] == 0.0 {
			pivot_row := count + 1
			for row := count + 2; row < n; row += 1 {
				if absolute(matrix[row][count]) > absolute(matrix[pivot_row][count]) do pivot_row = row
			}
			if pivot_row >= n || matrix[pivot_row][count] == 0.0 do return -1
			for column := 0; column < n; column += 1 {
				temporary := matrix[count][column]
				matrix[count][column] = matrix[pivot_row][column]
				matrix[pivot_row][column] = temporary
			}
			temporary := vector[count]
			vector[count] = vector[pivot_row]
			vector[pivot_row] = temporary
		}
		for row := 0; row < n; row += 1 {
			if row == count do continue
			fraction := matrix[row][count] / matrix[count][count]
			for column := 0; column < n; column += 1 {
				product := matrix[count][column] * fraction
				matrix[row][column] = matrix[row][column] - product
			}
			product := vector[count] * fraction
			vector[row] = vector[row] - product
		}
	}

	var coefficients: [MAX_POINTS]f64
	for index := 0; index < n; index += 1 {
		value := vector[index] / matrix[index][index]
		if value != value || value < -MAX_COEFFICIENT || value > MAX_COEFFICIENT || f64(i64(value)) != value do return -1
		coefficients[index] = value
	}

	var buffer: [SCRATCH_BYTES]u8
	position := append_text(&buffer[0], 0, "f(x)=")
	for index := 0; index < n; index += 1 {
		if index != 0 { buffer[position] = u8('+'); position += 1 }
		position = append_text(&buffer[0], position, "x^")
		position = append_i64(&buffer[0], position, i64(n - index - 1))
		buffer[position] = u8('*'); position += 1
		position = append_coefficient(&buffer[0], position, coefficients[index])
	}
	if position > MAX_CONTRACT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(position) do return -2
	for index := 0; index < position; index += 1 { output[index] = buffer[index] }
	return i64(position)
}
