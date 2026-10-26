module directed_perfect_phylogeny

@[export: 'directed_perfect_phylogeny']
pub fn directed_perfect_phylogeny(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 146 { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 1 || n0 > 12 || m0 < 1 || m0 > 12 || length != usize(2 + n0 * m0) { return -1 }
		n, m := int(n0), int(m0)
		mut sets := []u16{len: 12, init: 0}
		for row in 0 .. n {
			for col in 0 .. m {
				bit := input[2 + row*m + col]
				if bit != 0 && bit != 1 { return -1 }
				if bit == 1 { sets[col] |= u16(1) << u16(row) }
			}
		}
		mut feasible := true
		for a in 0 .. m {
			for b in a + 1 .. m {
				overlap := sets[a] & sets[b]
				if overlap != 0 && overlap != sets[a] && overlap != sets[b] { feasible = false }
			}
		}
		if output == nil || capacity < 8 { return -2 }
		result := i64(0)
		if feasible { result = 1 }
		bits := u64(result)
		for b in 0 .. 8 { output[b] = u8((bits >> u64(8*b)) & 255) }
		return 8
	}
}
