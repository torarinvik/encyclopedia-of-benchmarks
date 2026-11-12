module exp_of_set_power_series

const modulus = i64(998244353)
const max_n = 5
const max_size = 32

fn subset_size(mask int) int {
	mut count := 0
	mut value := mask
	for value > 0 { count += value & 1; value >>= 1 }
	return count
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'exp_of_set_power_series']
pub fn exp_of_set_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 33 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_n { return -1 }
		n := int(input[0])
		size := 1 << n
		if length != usize(1 + size) || input[1] != 0 { return -1 }
		for mask in 0 .. size {
			if input[1 + mask] < 0 || input[1 + mask] >= modulus { return -1 }
		}

		bytes := 8 * size
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }

		mut inverse := [6]i64{}
		mut values := [32]i64{}
		if n > 0 { inverse[1] = 1 }
		for k in 2 .. n + 1 {
			inverse[k] = modulus - (modulus / i64(k)) * inverse[int(modulus % i64(k))] % modulus
		}
		values[0] = 1
		for mask in 1 .. size {
			mut total := i64(0)
			mut subset := mask
			for subset > 0 {
				mut term := i64(subset_size(subset)) * input[1 + subset] % modulus
				term = term * values[mask ^ subset] % modulus
				total = (total + term) % modulus
				subset = (subset - 1) & mask
			}
			values[mask] = total * inverse[subset_size(mask)] % modulus
		}
		for mask in 0 .. size { store_le(mut output, 8 * mask, values[mask]) }
		return i64(bytes)
	}
}
