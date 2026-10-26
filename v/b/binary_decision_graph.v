module binary_decision_graph

fn put_i64(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'binary_decision_graph']
pub fn binary_decision_graph(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 65 { return -1 }
	unsafe {
		nv := input[0]
		if nv < 1 || nv > 6 || length != usize(1 + (1 << int(nv))) { return -1 }
		n := int(nv)
		count := 1 << n
		mut ids := []i64{len: 64, init: 0}
		mut next := []i64{len: 64, init: 0}
		mut vars := []i64{len: 63, init: 0}
		mut lows := []i64{len: 63, init: 0}
		mut highs := []i64{len: 63, init: 0}
		for i in 0 .. count {
			if input[i + 1] != 0 && input[i + 1] != 1 { return -1 }
			ids[i] = input[i + 1]
		}
		mut nodes := 0
		mut current_count := count
		for step in 0 .. n {
			variable := n - 1 - step
			next_count := current_count / 2
			for p in 0 .. next_count {
				lo, hi := ids[2 * p], ids[2 * p + 1]
				if lo == hi { next[p] = lo; continue }
				mut found := nodes
			mut j := nodes
				for j > 0 {
					j--
					if int(vars[j]) != variable { break }
					if lows[j] == lo && highs[j] == hi { found = j; break }
				}
				if found == nodes {
					vars[nodes] = i64(variable); lows[nodes] = lo; highs[nodes] = hi
					next[p] = i64(2 + nodes); nodes++
				} else { next[p] = i64(2 + found) }
			}
			for p in 0 .. next_count { ids[p] = next[p] }
			current_count = next_count
		}
		bytes := 8 * (2 + 3 * nodes)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, ids[0]); put_i64(mut output, 1, i64(nodes))
		for i in 0 .. nodes {
			put_i64(mut output, 2 + 3 * i, vars[i]); put_i64(mut output, 3 + 3 * i, lows[i]); put_i64(mut output, 4 + 3 * i, highs[i])
		}
		return i64(bytes)
	}
}
