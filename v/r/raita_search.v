module raita_search

@[export: 'raita_search']
pub fn raita_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 322 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 255 || input[1] < 1 || input[1] > 64 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + n + m) { return -1 }
		for i in 0 .. n + m {
			if input[2 + i] < 0 || input[2 + i] > 127 { return -1 }
		}
		mut positions := [255]i64{}
		mut match_count := 0
		if m <= n {
			mut shifts := [128]int{}
			for byte in 0 .. 128 { shifts[byte] = m }
			for i in 0 .. m - 1 { shifts[int(input[2 + n + i])] = m - i - 1 }
			middle := m / 2
			mut alignment := 0
			for alignment <= n - m {
				last := int(input[2 + alignment + m - 1])
				mut matches := input[2 + n + m - 1] == i64(last)
				if matches { matches = input[2 + n] == input[2 + alignment] }
				if matches { matches = input[2 + n + middle] == input[2 + alignment + middle] }
				if matches {
					mut index := 1
					for index + 1 < m && matches {
						if input[2 + n + index] != input[2 + alignment + index] { matches = false }
						index++
					}
					if matches {
						positions[match_count] = i64(alignment)
						match_count++
					}
				}
				alignment += shifts[last]
			}
		}
		output_bytes := match_count * 8
		if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. match_count {
			bits := u64(positions[i])
			for byte in 0 .. 8 {
				unsafe { output[i * 8 + byte] = u8(bits & 255) }
				bits >>= 8
			}
		}
		return i64(output_bytes)
	}
}
