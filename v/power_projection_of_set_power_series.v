module power_projection_of_set_power_series

const modulus = i64(998244353)
const max_n = 4
const max_m = 8
const max_size = 16
const max_input = 35

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'power_projection_of_set_power_series']
pub fn power_projection_of_set_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_n || input[1] < 0 || input[1] > max_m { return -1 }
		n := int(input[0])
		powers := int(input[1])
		size := 1 << n
		if length != usize(2 + 2 * size) { return -1 }

		mut series := [16]i64{}
		mut weights := [16]i64{}
		for mask in 0 .. size {
			a := input[2 + mask]
			w := input[2 + size + mask]
			if a < 0 || a >= modulus || w < 0 || w >= modulus { return -1 }
			series[mask] = a
			weights[mask] = w
		}

		bytes := 8 * powers
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }

		mut current := [16]i64{}
		mut next := [16]i64{}
		current[0] = 1
		for power in 0 .. powers {
			mut projection := i64(0)
			for mask in 0 .. size {
				projection = (projection + weights[mask] * current[mask]) % modulus
			}
			store_le(mut output, 8 * power, projection)
			if power + 1 == powers { break }
			for mask in 0 .. size {
				mut total := i64(0)
				mut subset := mask
				for {
					total = (total + current[subset] * series[mask ^ subset]) % modulus
					if subset == 0 { break }
					subset = (subset - 1) & mask
				}
				next[mask] = total
			}
			for mask in 0 .. size { current[mask] = next[mask] }
		}
		return i64(bytes)
	}
}
