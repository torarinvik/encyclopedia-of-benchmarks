module bezier_curve

const max_points = 16

fn integer_power(base f64, exponent int) f64 {
	mut result := 1.0
	for _ in 0 .. exponent { result *= base }
	return result
}

fn choose(n int, k_input int) u64 {
	mut k := k_input
	if k > n-k { k = n-k }
	mut result := u64(1)
	for index in 1 .. k+1 { result = result*u64(n-k+index)/u64(index) }
	return result
}

fn round_scaled(value f64) i64 {
	scaled := value * 1_000_000.0
	if scaled >= 0.0 { return i64(scaled+0.5) }
	return i64(scaled-0.5)
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset+byte] = u8((bits >> (8*byte)) & 0xff) }
	}
}

@[export: 'bezier_curve']
pub fn bezier_curve(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > 34 { return -1 }
	point_count_value := unsafe { values[0] }
	parameter_q := unsafe { values[1] }
	if point_count_value < 1 || point_count_value > max_points || parameter_q < 0 || parameter_q > 1_000_000 { return -1 }
	point_count := int(point_count_value)
	if int(length) != 2+2*point_count { return -1 }
	for index in 2 .. int(length) {
		value := unsafe { values[index] }
		if value < -1_000_000 || value > 1_000_000 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < 32 { return -2 }

	degree := point_count-1
	t := f64(parameter_q)/1_000_000.0
	mut x := f64(0)
	mut y := f64(0)
	mut dx := f64(0)
	mut dy := f64(0)
	for index in 0 .. point_count {
		weight := f64(choose(degree,index))*integer_power(1.0-t,degree-index)*integer_power(t,index)
		x += weight*f64(unsafe { values[2+2*index] })
		y += weight*f64(unsafe { values[3+2*index] })
	}
	for index in 0 .. degree {
		weight := f64(degree)*f64(choose(degree-1,index))*integer_power(1.0-t,degree-1-index)*integer_power(t,index)
		dx += weight*f64(unsafe { values[4+2*index]-values[2+2*index] })
		dy += weight*f64(unsafe { values[5+2*index]-values[3+2*index] })
	}
	write_i64_le(mut output, 0, round_scaled(x))
	write_i64_le(mut output, 8, round_scaled(y))
	write_i64_le(mut output, 16, round_scaled(dx))
	write_i64_le(mut output, 24, round_scaled(dy))
	return 32
}
