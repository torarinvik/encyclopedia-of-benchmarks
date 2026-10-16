package bezier_curve

import "core:c"

MAX_POINTS :: 16

integer_power :: proc "contextless" (base: f64, exponent: int) -> f64 {
	result := 1.0
	for _ in 0..<exponent do result *= base
	return result
}

choose :: proc "contextless" (n, k_input: int) -> u64 {
	k := min(k_input, n-k_input)
	result := u64(1)
	for index in 1..=k do result = result * u64(n-k+index) / u64(index)
	return result
}

round_scaled :: proc "contextless" (value: f64) -> i64 {
	scaled := value * 1_000_000.0
	if scaled >= 0 do return i64(scaled+0.5)
	return i64(scaled-0.5)
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 do output[offset+byte] = u8((bits >> u32(8*byte)) & 0xff)
}

@(export)
bezier_curve :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 34 do return -1
	point_count_value := values[0]
	parameter_q := values[1]
	if point_count_value < 1 || point_count_value > MAX_POINTS || parameter_q < 0 || parameter_q > 1_000_000 do return -1
	point_count := int(point_count_value)
	if int(length) != 2+2*point_count do return -1
	for index in 2..<int(length) {
		if values[index] < -1_000_000 || values[index] > 1_000_000 do return -1
	}
	if output == nil || output_capacity < 32 do return -2

	degree := point_count-1
	t := f64(parameter_q)/1_000_000.0
	x: f64 = 0.0
	y: f64 = 0.0
	dx: f64 = 0.0
	dy: f64 = 0.0
	for index in 0..<point_count {
		weight := f64(choose(degree, index))*integer_power(1.0-t, degree-index)*integer_power(t,index)
		x += weight*f64(values[2+2*index])
		y += weight*f64(values[3+2*index])
	}
	for index in 0..<degree {
		weight := f64(degree)*f64(choose(degree-1,index))*integer_power(1.0-t,degree-1-index)*integer_power(t,index)
		dx += weight*f64(values[4+2*index]-values[2+2*index])
		dy += weight*f64(values[5+2*index]-values[3+2*index])
	}
	write_i64_le(output, 0, round_scaled(x))
	write_i64_le(output, 8, round_scaled(y))
	write_i64_le(output, 16, round_scaled(dx))
	write_i64_le(output, 24, round_scaled(dy))
	return 32
}
