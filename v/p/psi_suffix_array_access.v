module psi_suffix_array_access

fn put_u64(mut output &u8, word int, value u64) {
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((value >> u64(8 * b)) & 255) } }
}

@[export: 'psi_suffix_array_access']
pub fn psi_suffix_array_access(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 5 || length > 67 { return -1 }
	unsafe {
		n0, query0, stride0 := input[0], input[1], input[2]
		if n0 < 1 || n0 > 32 || query0 < 0 || query0 >= n0 || stride0 < 1 || stride0 > n0 || length != usize(3 + 2 * n0) { return -1 }
		n, query, stride := int(n0), int(query0), int(stride0)
		mut destinations := [32]bool{}
		mut visited := [32]bool{}
		for i in 0 .. n {
			next, sample := input[3 + i], input[3 + n + i]
			if next < 0 || next >= n0 || destinations[int(next)] || sample < 0 || sample > n0 { return -1 }
			destinations[int(next)] = true
		}
		mut anchor := -1
		for i in 0 .. n { if input[3 + n + i] != 0 { anchor = i; break } }
		if anchor < 0 { return -1 }
		anchor_value := input[3 + n + anchor]
		if (anchor_value - 1) % stride0 != 0 { return -1 }
		mut full_sa := [32]u64{}
		mut rank, mut value := anchor, anchor_value
		for _ in 0 .. n {
			if visited[rank] { return -1 }
			visited[rank] = true
			full_sa[rank] = u64(value)
			rank = int(input[3 + rank])
			value = if value == n0 { 1 } else { value + 1 }
		}
		if rank != anchor || value != anchor_value { return -1 }
		for i in 0 .. n {
			expected := if (full_sa[i] - 1) % u64(stride) == 0 { i64(full_sa[i]) } else { i64(0) }
			if input[3 + n + i] != expected { return -1 }
		}
		rank = query
		mut hops := 0
		for input[3 + n + rank] == 0 {
			rank = int(input[3 + rank]); hops++
			if hops >= stride { return -1 }
		}
		mut position0 := input[3 + n + rank] - 1 - i64(hops)
		position0 %= n0
		if position0 < 0 { position0 += n0 }
		if output == nil || capacity < 16 { return -2 }
		put_u64(mut output, 0, u64(position0 + 1))
		put_u64(mut output, 1, u64(hops))
		return 16
	}
}
