fn ceil_log2(value int) int {
	mut exponent := 0
	mut power := 1
	for power < value { power *= 2; exponent++ }
	return exponent
}

@[export: 'radio_network_bgi_broadcast']
pub fn radio_network_bgi_broadcast(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 203 { return -1 }
		n64 := input[0]; source64 := input[1]; delta64 := input[2]
		if n64 < 2 || n64 > 8 || source64 < 0 || source64 >= n64 || delta64 < 2 || delta64 > 8 { return -1 }
		n := int(n64); source := int(source64); delta := int(delta64)
		k := 2 * ceil_log2(delta); t := ceil_log2(2 * n); tape_at := 3 + n; tape_count := n * t * k
		if length != usize(tape_at + tape_count) { return -1 }
		full := (u64(1) << n) - 1
		mut adjacency := []u64{len: n, init: 0}
		for v in 0 .. n {
			raw := input[3 + v]
			if raw < 0 || (u64(raw) & ~full) != 0 || (u64(raw) & (u64(1) << v)) != 0 { return -1 }
			adjacency[v] = u64(raw)
			if int(adjacency[v].count_ones()) > delta { return -1 }
		}
		for u in 0 .. n { for v in 0 .. n { if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1) { return -1 } } }
		for i in 0 .. tape_count { if input[tape_at + i] != 0 && input[tape_at + i] != 1 { return -1 } }
		output_bytes := 8 * (n + 3)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut informed := []bool{len: n, init: false}
		mut active := []bool{len: n, init: false}
		mut newly := []bool{len: n, init: false}
		mut calls := []int{len: n, init: 0}
		mut first_slot := []i64{len: n, init: -1}
		informed[source] = true; first_slot[source] = 0
		mut transmissions := i64(0); mut phases := i64(0)
		for phase in 0 .. n * t {
			mut starters := 0
			for v in 0 .. n { active[v] = informed[v] && calls[v] < t; newly[v] = false; if active[v] { starters++ } }
			if starters == 0 { break }
			for slot in 0 .. k {
				for sender in 0 .. n { if active[sender] { transmissions++ } }
				for receiver in 0 .. n {
					if informed[receiver] || newly[receiver] { continue }
					mut sender_count := 0
					for sender in 0 .. n { if active[sender] && ((adjacency[sender] >> receiver) & 1) != 0 { sender_count++ } }
					if sender_count == 1 { newly[receiver] = true; first_slot[receiver] = i64(phase * k + slot) }
				}
				for sender in 0 .. n { if active[sender] {
					at := tape_at + (sender * t + calls[sender]) * k + slot
					if slot + 1 == k || input[at] == 0 { active[sender] = false }
				} }
			}
			for v in 0 .. n { if informed[v] && calls[v] < t { calls[v]++ }; if newly[v] { informed[v] = true } }
			phases = i64(phase + 1)
		}
		mut fields := []i64{len: n + 3, init: 0}
		fields[0] = n64; fields[1] = phases; fields[2] = transmissions
		for v in 0 .. n { fields[3 + v] = first_slot[v] }
		for i in 0 .. n + 3 { bits := u64(fields[i]); for b in 0 .. 8 { output[8 * i + b] = u8((bits >> (8 * b)) & 255) } }
		return i64(output_bytes)
	}
}
