module zdd_family_count

fn put_i64(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'zdd_family_count']
pub fn zdd_family_count(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 34 { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 1 || n0 > 6 || m0 < 0 || m0 > 32 || length != usize(m0 + 2) { return -1 }
		n, m := int(n0), int(m0)
		limit := 1 << n
		mut ids := []i64{len: 64, init: 0}; mut next := []i64{len: 64, init: 0}
		mut vars := []i64{len: 63, init: 0}; mut lows := []i64{len: 63, init: 0}; mut highs := []i64{len: 63, init: 0}
		mut counts := []i64{len: 65, init: 0}; counts[1] = 1
		mut seen := []bool{len: 64, init: false}
		for i in 0 .. m {
			mask := input[2 + i]
			if mask < 0 || mask >= i64(limit) || seen[int(mask)] { return -1 }
			seen[int(mask)] = true; ids[int(mask)] = 1
		}
		mut nodes := 0; mut current_count := limit
		for variable in 0 .. n {
			next_count := current_count / 2
			for p in 0 .. next_count {
				low, high := ids[2*p], ids[2*p+1]
				if high == 0 { next[p] = low; continue }
				mut found := nodes; mut j := nodes
				for j > 0 {
					j--
					if int(vars[j]) != variable { break }
					if lows[j] == low && highs[j] == high { found = j; break }
				}
				if found == nodes {
					vars[nodes] = i64(variable); lows[nodes] = low; highs[nodes] = high
					counts[2+nodes] = counts[int(low)] + counts[int(high)]
					next[p] = i64(2+nodes); nodes++
				} else { next[p] = i64(2+found) }
			}
			for p in 0 .. next_count { ids[p] = next[p] }
			current_count = next_count
		}
		bytes := 8 * (3 + 3 * nodes)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, ids[0]); put_i64(mut output, 1, i64(nodes)); put_i64(mut output, 2, counts[int(ids[0])])
		for i in 0 .. nodes {
			put_i64(mut output, 3+3*i, vars[i]); put_i64(mut output, 4+3*i, lows[i]); put_i64(mut output, 5+3*i, highs[i])
		}
		return i64(bytes)
	}
}
