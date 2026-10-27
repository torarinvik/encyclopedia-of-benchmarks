module min_plus_distance_product

const max_input = 130
const max_output = 512
const inf = i64(1000000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'min_plus_distance_product']
pub fn min_plus_distance_product(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n0 := input[0]
		m0 := input[1]
		if n0 < 1 || n0 > 8 || m0 < 1 || m0 > 8 { return -1 }
		n := int(n0)
		m := int(m0)
		if length != usize(2 + 2 * n * m) { return -1 }
		mut values := []i64{len: int(length), init: 0}
		for i in 0 .. int(length) { values[i] = input[i] }
		for i in 2 .. int(length) { if values[i] < 0 || (values[i] > 1000 && values[i] != inf) { return -1 } }
		bytes := 8 * n * n
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut result := []i64{len: 64, init: 0}
		for i in 0 .. n {
			for j in 0 .. n {
				mut best := inf
				for k in 0 .. m {
					x := values[2 + i * m + k]
					y := values[2 + n * m + k * n + j]
					if x != inf && y != inf && x + y < best { best = x + y }
				}
				result[i * n + j] = best
			}
		}
		for i in 0 .. n * n { store_i64_le(mut output, 8 * i, result[i]) }
		return i64(bytes)
	}
}
