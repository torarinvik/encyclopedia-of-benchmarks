module aitken_delta_squared_sequence_transform

const max_terms = 64
const max_words = 66
const value_limit = i64(1000000)

fn aitken_gcd(left_value u64, right_value u64) u64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn aitken_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'aitken_delta_squared_sequence_transform']
pub fn aitken_delta_squared_sequence_transform(values &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if length < 3 || length > max_words { return -1 }
	unsafe {
		if values == nil { return -1 }
		n_value := values[0]
		if n_value < 2 || n_value > max_terms || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		for index in 0 .. n {
			value := values[index + 1]
			if value < -value_limit || value > value_limit { return -1 }
		}
		output_length := 16 * (n - 2)
		if output == nil || output_capacity < usize(output_length) { return -2 }

		for index in 0 .. n - 2 {
			first := values[index + 1]
			middle := values[index + 2]
			last := values[index + 3]
			mut numerator := first * last - middle * middle
			mut denominator := first - 2 * middle + last
			if denominator == 0 {
				if first == middle && middle == last {
					numerator = first
					denominator = 1
				} else {
					numerator = 0
				}
			} else {
				if denominator < 0 { numerator = -numerator; denominator = -denominator }
				magnitude := if numerator < 0 { u64(-numerator) } else { u64(numerator) }
				divisor := aitken_gcd(magnitude, u64(denominator))
				numerator /= i64(divisor)
				denominator /= i64(divisor)
			}
			aitken_store_i64(&output[0], index * 16, numerator)
			aitken_store_i64(&output[0], index * 16 + 8, denominator)
		}
		return i64(output_length)
	}
}
