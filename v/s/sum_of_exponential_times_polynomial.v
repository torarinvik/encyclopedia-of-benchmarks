module sum_of_exponential_times_polynomial

const modulus = i64(998244353)
const max_degree = 32

fn sepm_shift(source [33]i64, shift u64, degree int, choose [1089]i64) [33]i64 {
	mut powers := [33]i64{}
	mut destination := [33]i64{}
	powers[0] = 1
	reduced_shift := i64(shift % u64(modulus))
	for i in 1 .. degree + 1 { powers[i] = powers[i - 1] * reduced_shift % modulus }
	for d in 0 .. degree + 1 {
		mut total := i64(0)
		for k in 0 .. d + 1 {
			term := choose[d * 33 + k] * powers[d - k] % modulus
			total = (total + term * source[k]) % modulus
		}
		destination[d] = total
	}
	return destination
}

@[export: 'sum_of_exponential_times_polynomial']
pub fn sum_of_exponential_times_polynomial(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		r, degree_value, n_value := input[0], input[1], input[2]
		if r < 0 || r >= modulus || degree_value < 0 || degree_value > max_degree ||
			n_value < 0 || n_value > 1_000_000_000_000_000_000 { return -1 }
		degree := int(degree_value)
		mut choose := [1089]i64{}
		choose[0] = 1
		for d in 1 .. degree + 1 {
			choose[d * 33] = 1
			choose[d * 33 + d] = 1
			for k in 1 .. d { choose[d * 33 + k] = (choose[(d - 1) * 33 + k - 1] + choose[(d - 1) * 33 + k]) % modulus }
		}
		mut accumulated := [33]i64{}
		mut block := [33]i64{}
		block[0] = 1
		mut accumulated_power := i64(1)
		mut block_power := r
		mut accumulated_length := u64(0)
		mut block_length := u64(1)
		mut remaining := u64(n_value)
		for remaining > 0 {
			if (remaining & u64(1)) != 0 {
				shifted := sepm_shift(block, accumulated_length, degree, choose)
				for d in 0 .. degree + 1 { accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % modulus }
				accumulated_power = accumulated_power * block_power % modulus
				accumulated_length += block_length
			}
			shifted_block := sepm_shift(block, block_length, degree, choose)
			for d in 0 .. degree + 1 { block[d] = (block[d] + block_power * shifted_block[d]) % modulus }
			block_power = block_power * block_power % modulus
			block_length <<= 1
			remaining >>= 1
		}
		return accumulated[degree]
	}
}
