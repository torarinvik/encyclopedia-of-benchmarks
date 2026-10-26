// Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
@[export: 'gbbs_approximate_set_cover']
pub fn gbbs_approximate_set_cover(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 10 { return -1 }
		ns64 := input[0]
		if ns64 < 1 || ns64 > 8 { return -1 }
		ns := int(ns64)
		ne := ns
		if length != usize(1 + ns) { return -1 }
		valid := u16((1 << ne) - 1)
		mut sets := []u16{len: 8, init: 0}
		for s in 0 .. ns {
			if input[1+s] < 0 || (u64(input[1+s]) & ~u64(valid)) != 0 { return -1 }
			sets[s] = u16(input[1+s])
			if sets[s] & u16(1 << s) != 0 { return -1 }
		}
		for u in 0 .. ns {
			for v in 0 .. ns {
				if (sets[u] >> v) & 1 != (sets[v] >> u) & 1 { return -1 }
			}
		}
		if output == nil || capacity < 16 { return -2 }
		mut uncovered := valid
		mut selected := u16(0)
		mut bucket := []int{len: 8, init: 0}
		for s in 0 .. ns {
			mut bits := sets[s]
			for bits != 0 { bits &= bits - 1; bucket[s]++ }
		}
		mut round := 0
		for uncovered != 0 {
			mut degree := []int{len: 8, init: 0}
			mut top := 0
			for s in 0 .. ns { if bucket[s] > top { top = bucket[s] } }
			if top == 0 { break }
			mut eligible := []bool{len: 8, init: false}
			mut eligible_count := 0
			for s in 0 .. ns {
				if bucket[s] == top {
					mut bits := sets[s] & uncovered
					for bits != 0 { bits &= bits - 1; degree[s]++ }
					bucket[s] = degree[s]
					eligible[s] = degree[s] >= top
					if eligible[s] { eligible_count++ }
				}
			}
			mut priority := []int{len: 8, init: 0}
			mut priority_count := 0
			for r in 0 .. ns {
				s := (round + r) % ns
				if eligible[s] { priority[priority_count] = s; priority_count++ }
			}
			mut wins := []int{len: 8, init: 0}
			for e in 0 .. ne {
				bit := u16(1 << e)
				if uncovered & bit == 0 { continue }
				for r in 0 .. priority_count {
					s := priority[r]
					if sets[s] & bit != 0 { wins[s]++; break }
				}
			}
			mut round_cover := u16(0)
			for s in 0 .. ns { if eligible[s] && wins[s] >= top { round_cover |= u16(1 << s) } }
			if round_cover == 0 && eligible_count != 0 { return -1 }
			selected |= round_cover
			mut covered := u16(0)
			for s in 0 .. ns { if round_cover & u16(1 << s) != 0 { covered |= sets[s] } }
			uncovered &= ~covered
			for s in 0 .. ns { if round_cover & u16(1 << s) != 0 { bucket[s] = 0 } }
			round++
		}
		for i, value in [selected, uncovered] {
			bits := u64(value)
			for byte in 0 .. 8 { output[i*8+byte] = u8((bits >> (byte*8)) & 255) }
		}
		return 16
	}
}
