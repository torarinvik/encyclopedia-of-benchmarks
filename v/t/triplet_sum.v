fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'triplet_sum']
pub fn triplet_sum(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	max_items := 10
	if length < 1 || length > usize(max_items + 1) || isnil(input) { return -1 }
	target := unsafe { input[0] }
	if target < -3000000 || target > 3000000 { return -1 }
	item_count := int(length - 1)
	for index in 0 .. item_count {
		value := unsafe { input[index + 1] }
		if value < -1000000 || value > 1000000 { return -1 }
	}
	if output_capacity < 24 || isnil(output) { return -2 }

	mut result := [3]i64{}
	mut found := false
	for first in 0 .. item_count {
		if found { break }
		for second in 0 .. item_count {
			if found { break }
			if second == first { continue }
			for third in 0 .. item_count {
				if third == first || third == second { continue }
				a := unsafe { input[first + 1] }
				b := unsafe { input[second + 1] }
				c := unsafe { input[third + 1] }
				if a + b + c == target {
					result[0] = a
					result[1] = b
					result[2] = c
					if result[0] > result[1] { result[0], result[1] = result[1], result[0] }
					if result[1] > result[2] { result[1], result[2] = result[2], result[1] }
					if result[0] > result[1] { result[0], result[1] = result[1], result[0] }
					found = true
					break
				}
			}
		}
	}
	for index in 0 .. 3 { put_i64_le(mut output, index * 8, result[index]) }
	return 3
}
