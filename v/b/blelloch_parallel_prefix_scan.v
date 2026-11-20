module blelloch_parallel_prefix_scan

const max_items = 64
const max_input_words = 66

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'blelloch_parallel_prefix_scan']
pub fn blelloch_parallel_prefix_scan(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_words { return -1 }
	n64 := unsafe { input[0] }
	if n64 < 1 || n64 > max_items { return -1 }
	n := int(n64)
	if int(length) != n + 1 { return -1 }

	mut tree := [max_items]i64{}
	mut padded := 1
	for padded < n { padded <<= 1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -1000000 || value > 1000000 { return -1 }
		tree[i] = value
	}
	if output == nil || output_capacity < usize(n * 8) { return -2 }

	mut stride := 2
	for stride <= padded {
		half := stride >> 1
		mut right := stride - 1
		for right < padded {
			tree[right] += tree[right - half]
			right += stride
		}
		stride <<= 1
	}
	tree[padded - 1] = 0
	stride = padded
	for stride >= 2 {
		half := stride >> 1
		mut right := stride - 1
		for right < padded {
			left := right - half
			partial := tree[left]
			tree[left] = tree[right]
			tree[right] += partial
			right += stride
		}
		stride >>= 1
	}
	for i in 0 .. n { store_i64_le(mut output, i * 8, tree[i]) }
	return i64(n * 8)
}
