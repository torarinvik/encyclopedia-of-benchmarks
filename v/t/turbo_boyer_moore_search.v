module turbo_boyer_moore_search

@[export: 'turbo_boyer_moore_search']
pub fn turbo_boyer_moore_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
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
			mut bad := [128]int{}
			mut suffix := [64]int{}
			mut good := [64]int{}
			for byte in 0 .. 128 { bad[byte] = m }
			for i in 0 .. m - 1 { bad[int(input[2 + n + i])] = m - i - 1 }
			suffix[m - 1] = m
			mut g := m - 1
			mut f := 0
			mut i := m - 2
			for i >= 0 {
				if i > g && suffix[i + m - 1 - f] < i - g {
					suffix[i] = suffix[i + m - 1 - f]
				} else {
					if i < g { g = i }
					f = i
					for g >= 0 && input[2 + n + g] == input[2 + n + g + m - 1 - f] { g-- }
					suffix[i] = f - g
				}
				i--
			}
			for j in 0 .. m { good[j] = m }
			mut border := 0
			i = m - 1
			for i >= 0 {
				if suffix[i] == i + 1 {
					for border < m - 1 - i {
						if good[border] == m { good[border] = m - 1 - i }
						border++
					}
				}
				i--
			}
			for j in 0 .. m - 1 { good[m - 1 - suffix[j]] = m - 1 - j }

			mut alignment := 0
			mut remembered := 0
			mut shift := m
			for alignment <= n - m {
				i = m - 1
				for i >= 0 && input[2 + n + i] == input[2 + alignment + i] {
					i--
					if remembered != 0 && i == m - 1 - shift { i -= remembered }
				}
				if i < 0 {
					positions[match_count] = i64(alignment)
					match_count++
					shift = good[0]
					remembered = m - shift
				} else {
					matched := m - 1 - i
					turbo_shift := remembered - matched
					bad_shift := bad[int(input[2 + alignment + i])] - m + 1 + i
					gs := good[i]
					shift = max(turbo_shift, max(bad_shift, gs))
					if shift == gs {
						remembered = min(m - shift, matched)
					} else {
						if turbo_shift < bad_shift && shift < remembered + 1 { shift = remembered + 1 }
						remembered = 0
					}
				}
				alignment += shift
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
