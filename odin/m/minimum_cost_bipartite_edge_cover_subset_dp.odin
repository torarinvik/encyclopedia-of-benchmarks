package minimum_cost_bipartite_edge_cover_subset_dp

import "core:c"

INF :: i64(1) << 60
MAX_STATES :: 256

@(export)
minimum_cost_bipartite_edge_cover_subset_dp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 67 do return -1
	left_value, right_value := input[0], input[1]
	if left_value < 1 || left_value > 8 || right_value < 1 || right_value > 8 do return -1
	left_count, right_count := int(left_value), int(right_value)
	if length != c.size_t(2 + left_count * right_count) do return -1
	for edge := 0; edge < left_count * right_count; edge += 1 {
		cost := input[2 + edge]
		if cost < 0 || cost > 1000 do return -1
	}

	states := 1 << right_count
	current: [MAX_STATES]i64
	following: [MAX_STATES]i64
	subset_cost: [MAX_STATES]i64
	for mask := 0; mask < states; mask += 1 { current[mask] = INF }
	current[0] = 0
	for left := 0; left < left_count; left += 1 {
		subset_cost[0] = 0
		for subset := 1; subset < states; subset += 1 {
			low_bit := subset & (~subset + 1)
			right := 0
			scan := low_bit
			for scan > 1 { scan >>= 1; right += 1 }
			subset_cost[subset] = subset_cost[subset ^ low_bit] + input[2 + left * right_count + right]
		}
		for mask := 0; mask < states; mask += 1 { following[mask] = INF }
		for covered := 0; covered < states; covered += 1 {
			if current[covered] == INF do continue
			for selected := 1; selected < states; selected += 1 {
				combined := covered | selected
				candidate := current[covered] + subset_cost[selected]
				if candidate < following[combined] { following[combined] = candidate }
			}
		}
		for mask := 0; mask < states; mask += 1 { current[mask] = following[mask] }
	}
	return current[states - 1]
}
