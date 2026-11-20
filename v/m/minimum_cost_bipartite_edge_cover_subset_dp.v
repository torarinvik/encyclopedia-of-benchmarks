const edge_cover_inf = i64(1) << 60
const edge_cover_max_states = 256

@[export: 'minimum_cost_bipartite_edge_cover_subset_dp']
pub fn minimum_cost_bipartite_edge_cover_subset_dp(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
	unsafe {
		left_value := input[0]
		right_value := input[1]
		if left_value < 1 || left_value > 8 || right_value < 1 || right_value > 8 { return -1 }
		left_count := int(left_value)
		right_count := int(right_value)
		if int(length) != 2 + left_count * right_count { return -1 }
		for edge in 0 .. left_count * right_count {
			cost := input[2 + edge]
			if cost < 0 || cost > 1000 { return -1 }
		}

		states := 1 << right_count
		mut current := [edge_cover_max_states]i64{}
		mut following := [edge_cover_max_states]i64{}
		mut subset_cost := [edge_cover_max_states]i64{}
		for mask in 0 .. states { current[mask] = edge_cover_inf }
		current[0] = 0
		for left in 0 .. left_count {
			subset_cost[0] = 0
			for subset in 1 .. states {
				low_bit := subset & (0 - subset)
				mut right := 0
				mut scan := low_bit
				for scan > 1 {
					scan >>= 1
					right++
				}
				subset_cost[subset] = subset_cost[subset ^ low_bit] + input[2 + left * right_count + right]
			}
			for mask in 0 .. states { following[mask] = edge_cover_inf }
			for covered in 0 .. states {
				if current[covered] == edge_cover_inf { continue }
				for selected in 1 .. states {
					combined := covered | selected
					candidate := current[covered] + subset_cost[selected]
					if candidate < following[combined] { following[combined] = candidate }
				}
			}
			for mask in 0 .. states { current[mask] = following[mask] }
		}
		return current[states - 1]
	}
}
