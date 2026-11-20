module lentz_continued_fraction_convergents

const max_terms = 8
const max_input_length = 19
const modulus = i64(998244353)

fn normalize(input i64) i64 {
	mut value := input % modulus
	if value < 0 { value += modulus }
	return value
}

fn power(base_input i64, exponent_input i64) i64 {
	mut base := normalize(base_input)
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'lentz_continued_fraction_convergents']
pub fn lentz_continued_fraction_convergents(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > max_terms { return -1 }
		count := int(count_value)
		if length != usize(2 + 2*count) { return -1 }
		for i in 1 .. length {
			if input[i] < 0 || input[i] >= modulus { return -1 }
		}
		mut value := input[1]
		if value == 0 { return -1 }
		mut c_ratio := value
		mut d_ratio := i64(0)
		mut trace := [max_terms + 2]i64{}
		trace[0] = value
		for index in 0 .. count {
			numerator, denominator := input[2+2*index], input[3+2*index]
			d_denominator := normalize(denominator + numerator*d_ratio)
			if d_denominator == 0 || c_ratio == 0 { return -1 }
			c_value := normalize(denominator + numerator*power(c_ratio, modulus-2))
			if c_value == 0 { return -1 }
			d_ratio = power(d_denominator, modulus-2)
			value = value*c_value%modulus*d_ratio%modulus
			c_ratio = c_value
			trace[index+1] = value
		}
		output_bytes := 8*(count+2)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		store_i64_le(mut output, 0, i64(count+1))
		for i in 0 .. count + 1 { store_i64_le(mut output, 8*(i+1), trace[i]) }
		return i64(output_bytes)
	}
}
