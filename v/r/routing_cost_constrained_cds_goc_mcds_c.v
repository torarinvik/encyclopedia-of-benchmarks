// Clean-room bounded GOC-MCDS-C construction trace.
module routing_cost_constrained_cds_goc_mcds_c

const max_n = 8
const max_input = 17

fn put64(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'routing_cost_constrained_cds_goc_mcds_c']
pub fn routing_cost_constrained_cds_goc_mcds_c(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input || input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(1+2*n) { return -1 }
		full := (u64(1) << n) - 1
		mut adjacency := [max_n]u64{init: 0}
		mut ids := [max_n]i64{init: 0}
		for v in 0 .. n {
			mask := input[1+v]
			ids[v] = input[1+n+v]
			if mask < 0 || u64(mask) > full || (u64(mask)&(u64(1)<<v)) != 0 || ids[v] < 1 || ids[v] > 1000 { return -1 }
			adjacency[v] = u64(mask)
			for u in 0 .. v { if ids[u] == ids[v] { return -1 } }
		}
		for u in 0 .. n { for v in 0 .. n { if ((adjacency[u]>>v)&1) != ((adjacency[v]>>u)&1) { return -1 } } }
		mut reached := u64(1)
		for {
			mut expanded := reached
			for v in 0 .. n { if ((reached>>v)&1) != 0 { expanded |= adjacency[v] } }
			if expanded == reached { break }
			reached = expanded
		}
		if reached != full { return -1 }
		mut white := full
		mut independent := u64(0)
		for white != 0 {
			mut black := u64(0)
			for v in 0 .. n {
				if ((white>>v)&1) == 0 { continue }
				mut lower := false
				for u in 0 .. n { if ((white>>u)&1) != 0 && ((adjacency[v]>>u)&1) != 0 && ids[u] < ids[v] { lower = true } }
				if !lower { black |= u64(1)<<v }
			}
			if black == 0 { return -1 }
			independent |= black
			mut removed := black
			for v in 0 .. n { if ((black>>v)&1) != 0 { removed |= adjacency[v] } }
			white &= ~removed
		}
		mut order := [max_n]int{init: 0}
		for i in 0 .. n {
			order[i] = i
			mut j := i
			for j > 0 && ids[order[j-1]] > ids[order[j]] { order[j-1], order[j] = order[j], order[j-1]; j-- }
		}
		mut connectors := u64(0)
		for a in 0 .. n {
			source := order[a]
			if ((independent>>source)&1) == 0 { continue }
			for b in (a+1) .. n {
				target := order[b]
				if ((independent>>target)&1) == 0 { continue }
				mut parent := [max_n]int{init: -2}
				mut queue := [max_n]int{init: 0}
				mut head := 0
				mut tail := 1
				parent[source] = -1
				queue[0] = source
				for head < tail && parent[target] == -2 {
					current := queue[head]
					head++
					for oi in 0 .. n {
						next := order[oi]
						if ((adjacency[current]>>next)&1) != 0 && parent[next] == -2 { parent[next] = current; queue[tail] = next; tail++ }
					}
				}
				if parent[target] == -2 { return -1 }
				mut path := [max_n]int{init: 0}
				mut path_length := 0
				mut current := target
				for current != source { path[path_length] = current; path_length++; current = parent[current] }
				path[path_length] = source
				path_length++
				if path_length <= 4 { for i in 1 .. (path_length-1) { connectors |= u64(1)<<path[i] } }
			}
		}
		if output == nil || capacity < 16 { return -2 }
		mut staged := [16]u8{init: 0}
		put64(mut staged[0], 0, i64(independent))
		put64(mut staged[0], 8, i64(independent|connectors))
		for i in 0 .. 16 { output[i] = staged[i] }
		return 16
	}
}
