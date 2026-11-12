module bernoulli_number

const modulus = i64(998244353)
const max_n = 32

fn modular_power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'bernoulli_number']
pub fn bernoulli_number(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		n64 := input[0]
		if n64 < 0 || n64 > i64(max_n) { return -1 }
		n := int(n64)
		output_bytes := 4 * (n + 1)
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut inverse := [34]i64{}
		mut bernoulli := [33]i64{}
		inverse[1] = 1
		for i in 2 .. n + 2 {
			inverse[i] = modular_power(i64(i), modulus - 2)
		}

		bernoulli[0] = 1
		for m in 1 .. n + 1 {
			mut choose := i64(1)
			mut total := i64(0)
			for k in 0 .. m {
				total = (total + choose * bernoulli[k]) % modulus
				choose = choose * i64(m + 1 - k) % modulus * inverse[k + 1] % modulus
			}
			bernoulli[m] = ((modulus - total) % modulus) * inverse[m + 1] % modulus
		}

		for i in 0 .. n + 1 {
			value := u32(bernoulli[i])
			output[4 * i] = u8(value)
			output[4 * i + 1] = u8(value >> 8)
			output[4 * i + 2] = u8(value >> 16)
			output[4 * i + 3] = u8(value >> 24)
		}
		return i64(output_bytes)
	}
}
