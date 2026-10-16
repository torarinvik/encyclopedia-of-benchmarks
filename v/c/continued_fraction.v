module continued_fraction

fn gcd_positive(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'continued_fraction']
pub fn continued_fraction(input &i64, length usize, output &u8, capacity usize) i64 {
	if input == nil || length != 2 { return -1 }
	mut numerator := unsafe { input[0] }
	mut denominator := unsafe { input[1] }
	if numerator < -1000000 || numerator > 1000000 || denominator < -1000000 ||
		denominator > 1000000 || denominator == 0 { return -1 }
	divisor := gcd_positive(abs(numerator), abs(denominator))
	numerator /= divisor
	denominator /= divisor
	if denominator < 0 { numerator = -numerator; denominator = -denominator }
	mut coefficients := [32]i64{}
	mut count := 0
	for {
		mut quotient := numerator / denominator
		mut remainder := numerator % denominator
		if remainder < 0 { quotient--; remainder += denominator }
		if count == coefficients.len { return -1 }
	coefficients[count] = quotient
		count++
		if remainder == 0 { break }
		numerator = denominator
		denominator = remainder
	}
	bytes := count * 8
	if bytes > capacity || output == nil { return -2 }
	for index in 0 .. count {
		bits := u64(coefficients[index])
		for byte in 0 .. 8 {
			unsafe { output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
	}
	return i64(bytes)
}
