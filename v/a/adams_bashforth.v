module adams_bashforth

fn coefficient(order i64, offset int) i64 {
	if order == 2 { return if offset == 0 { 3 } else { -1 } }
	if order == 3 { return if offset == 0 { 23 } else if offset == 1 { -16 } else { 5 } }
	if order == 4 { return if offset == 0 { 55 } else if offset == 1 { -59 } else if offset == 2 { 37 } else { -9 } }
	return if offset == 0 { 1901 } else if offset == 1 { -2774 } else if offset == 2 { -2616 } else if offset == 3 { -1274 } else { 251 }
}

fn append_integer(value_input i64, output &u8, position_input usize) usize {
	mut value := value_input
	mut digits := [24]u8{}
	mut count := usize(0)
	mut position := position_input
	if value < 0 {
		unsafe { output[position] = u8(`-`) }
		position++
		value = -value
	}
	for {
		digits[count] = u8(value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { output[position] = u8(`0`) + digits[count] }
		position++
	}
	return position
}

@[export: 'adams_bashforth']
pub fn adams_bashforth(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 4 { return -1 }
	order := unsafe { values[0] }
	steps := unsafe { values[1] }
	if order < 2 || order > 5 || steps < 1 || steps > 4 || length != usize(order + 2) { return -1 }
	mut x := [14]f64{}
	mut y := [14]f64{}
	for i in 0 .. int(order) {
		initial := unsafe { values[i + 2] }
		if initial < -100000 || initial > 100000 { return -1 }
		x[i] = f64(i) * 0.25
		y[i] = f64(initial) / 100000.0
	}
	denominator := if order == 2 { 2.0 } else if order == 3 { 12.0 } else if order == 4 { 24.0 } else { 720.0 }
	mut iterations := int(steps)
	if order == 3 || order == 5 { iterations++ }
	mut count := int(order)
	for _ in 0 .. iterations {
		mut weighted := f64(0)
		for offset in 0 .. int(order) {
			current := count - 1 - offset
			weighted += f64(coefficient(order, offset)) * (x[current] + y[current])
		}
		y[count] = y[count - 1] + (0.25 / denominator) * weighted
		x[count] = x[count - 1] + 0.25
		count++
	}
	mut encoded := [256]u8{}
	mut position := usize(0)
	for i in 0 .. count {
		if i > 0 { unsafe { encoded[position] = u8(`,`) }; position++ }
		position = append_integer(i64(y[i] * 1000000.0), &encoded[0], position)
	}
	if output_capacity < position { return -2 }
	unsafe { for i in 0 .. position { output[i] = encoded[i] } }
	return i64(position)
}
