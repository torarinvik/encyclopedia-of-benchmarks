package adams_bashforth

import "core:c"

coefficient :: proc "contextless" (order: i64, offset: int) -> i64 {
	if order == 2 { if offset == 0 do return 3; return -1 }
	if order == 3 { if offset == 0 do return 23; if offset == 1 do return -16; return 5 }
	if order == 4 { if offset == 0 do return 55; if offset == 1 do return -59; if offset == 2 do return 37; return -9 }
	if offset == 0 do return 1901
	if offset == 1 do return -2774
	if offset == 2 do return -2616
	if offset == 3 do return -1274
	return 251
}

append_integer :: proc "contextless" (value_input: i64, output: [^]u8, position_input: c.size_t) -> c.size_t {
	value := value_input
	digits: [24]u8
	count := c.size_t(0)
	position := position_input
	if value < 0 { output[position] = u8('-'); position += 1; value = -value }
	for {
		digits[count] = u8(value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		output[position] = u8('0') + digits[count]
		position += 1
	}
	return position
}

@(export)
adams_bashforth :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 do return -1
	order, steps := values[0], values[1]
	if order < 2 || order > 5 || steps < 1 || steps > 4 || length != c.size_t(order + 2) do return -1
	var x, y: [14]f64
	for i := 0; i < int(order); i += 1 {
		if values[i + 2] < -100000 || values[i + 2] > 100000 do return -1
		x[i] = f64(i) * 0.25
		y[i] = f64(values[i + 2]) / 100000.0
	}
	denominator := f64(720)
	if order == 2 { denominator = 2 }
	if order == 3 { denominator = 12 }
	if order == 4 { denominator = 24 }
	iterations := int(steps)
	if order == 3 || order == 5 { iterations += 1 }
	count := int(order)
	for iteration := 0; iteration < iterations; iteration += 1 {
		weighted := f64(0)
		for offset := 0; offset < int(order); offset += 1 {
			current := count - 1 - offset
			weighted += f64(coefficient(order, offset)) * (x[current] + y[current])
		}
		y[count] = y[count - 1] + (0.25 / denominator) * weighted
		x[count] = x[count - 1] + 0.25
		count += 1
	}
	encoded: [256]u8
	position := c.size_t(0)
	for i := 0; i < count; i += 1 {
		if i > 0 { encoded[position] = u8(','); position += 1 }
		position = append_integer(i64(y[i] * 1000000.0), &encoded, position)
	}
	if output == nil || output_capacity < position do return -2
	for i := c.size_t(0); i < position; i += 1 { output[i] = encoded[i] }
	return i64(position)
}
