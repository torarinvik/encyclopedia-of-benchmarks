module euler_alternating_series_transform

const max_terms = 16
const max_words = 18
const value_limit = i64(1000000)
const output_bytes = 16

fn euler_gcd(left_value u64, right_value u64) u64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn euler_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'euler_alternating_series_transform']
pub fn euler_alternating_series_transform(values &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_words { return -1 }
	unsafe {
		if values == nil { return -1 }
		n_value := values[0]
		if n_value < 1 || n_value > max_terms || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		for index in 0 .. n {
			value := values[index + 1]
			if value < -value_limit || value > value_limit { return -1 }
		}
		if output == nil || output_capacity < usize(output_bytes) { return -2 }

		mut numerator := i64(0)
		for order in 0 .. n {
			mut difference := i64(0)
			mut coefficient := i64(1)
			for index := 0; index <= order; index++ {
				term := values[order - index + 1]
				if index % 2 == 0 { difference += coefficient * term }
				else { difference -= coefficient * term }
				if index < order {
					coefficient = coefficient * i64(order - index) / i64(index + 1)
				}
			}
			weight := i64(1) << (n - order - 1)
			weighted := difference * weight
			if order % 2 == 0 { numerator += weighted }
			else { numerator -= weighted }
		}

		mut denominator := i64(1) << n
		magnitude := if numerator < 0 { u64(-numerator) } else { u64(numerator) }
		divisor := euler_gcd(magnitude, u64(denominator))
		numerator /= i64(divisor)
		denominator /= i64(divisor)
		euler_store_i64(&output[0], 0, numerator)
		euler_store_i64(&output[0], 8, denominator)
		return i64(output_bytes)
	}
}
