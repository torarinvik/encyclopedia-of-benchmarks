module apsp_min_plus_repeated_squaring

const max_n = 8
const max_input = 65
const inf = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'apsp_min_plus_repeated_squaring']
pub fn apsp_min_plus_repeated_squaring(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n0 := input[0]
		if n0 < 1 || n0 > max_n { return -1 }
		n := int(n0)
		if length != usize(1 + n * n) { return -1 }
		mut current := []i64{len: 64, init: 0}
		mut next := []i64{len: 64, init: 0}
		for i in 0 .. n {
			for j in 0 .. n {
				value := input[1 + i * n + j]
				if (i == j && value != 0) || (i != j && value != inf && (value < 1 || value > 1000)) { return -1 }
				current[i * n + j] = value
			}
		}
		mut edge_bound := 1
		for edge_bound < n - 1 {
			for i in 0 .. n {
				for j in 0 .. n {
					mut best := inf
					for k in 0 .. n {
						left := current[i * n + k]
						right := current[k * n + j]
						if left != inf && right != inf && left + right < best { best = left + right }
					}
					next[i * n + j] = best
				}
			}
			for index in 0 .. n * n { current[index] = next[index] }
			edge_bound *= 2
		}
		bytes := 8 * n * n
		if output == nil || capacity < usize(bytes) { return -2 }
		for index in 0 .. n * n { store_i64_le(mut output, 8 * index, current[index]) }
		return i64(bytes)
	}
}
