package ptrdist_ks

import "core:c"

MAX_MODULES :: 8
MAX_NETS :: 16
MAX_INPUT :: 146

edge_cut :: proc(side: [MAX_MODULES]int, nets: [MAX_NETS][MAX_MODULES]int, degrees: [MAX_NETS]int, net_count: int) -> int {
	total := 0
	for net in 0..<net_count {
		for i in 0..<degrees[net] {
			for j in i+1..<degrees[net] {
				if side[nets[net][i]] != side[nets[net][j]] { total += 1 }
			}
		}
	}
	return total
}

net_cut :: proc(side: [MAX_MODULES]int, nets: [MAX_NETS][MAX_MODULES]int, degrees: [MAX_NETS]int, net_count: int) -> int {
	total := 0
	for net in 0..<net_count {
		first := side[nets[net][0]]
		for i in 1..<degrees[net] {
			if side[nets[net][i]] != first { total += 1; break }
		}
	}
	return total
}

@(export)
ptrdist_ks :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	module_value := input[0]
	net_value := input[1]
	if module_value < 2 || module_value > MAX_MODULES || module_value%2 != 0 || net_value < 0 || net_value > MAX_NETS do return -1
	modules := int(module_value)
	net_count := int(net_value)
	nets: [MAX_NETS][MAX_MODULES]int
	degrees: [MAX_NETS]int
	cursor := c.size_t(2)
	for net in 0..<net_count {
		if cursor >= length do return -1
		degree_value := input[cursor]
		cursor += 1
		if degree_value < 2 || degree_value > module_value || cursor+c.size_t(degree_value) > length do return -1
		degree := int(degree_value)
		degrees[net] = degree
		for i in 0..<degree {
			member_value := input[cursor]
			cursor += 1
			if member_value < 0 || member_value >= module_value do return -1
			member := int(member_value)
			for j in 0..<i { if nets[net][j] == member do return -1 }
			nets[net][i] = member
		}
	}
	if cursor != length do return -1

	half := modules/2
	order_a: [MAX_MODULES]int
	order_b: [MAX_MODULES]int
	side: [MAX_MODULES]int
	for i in 0..<half { order_a[i] = i; order_b[i] = half+i; side[i] = 0; side[half+i] = 1 }
	accepted_passes := 0
	for {
		work := side
		remaining_a := order_a
		remaining_b := order_b
		selected_a: [MAX_MODULES]int
		selected_b: [MAX_MODULES]int
		count_a, count_b := half, half
		cumulative_gain := 0
		best_gain := -2147483647
		best_prefix := 0
		for step in 0..<half {
			baseline := edge_cut(work, nets, degrees, net_count)
			pair_gain := -2147483647
			chosen_a, chosen_b := -1, -1
			for ai in 0..<count_a {
				a := remaining_a[ai]
				for bi in 0..<count_b {
					b := remaining_b[bi]
					work[a] = 1; work[b] = 0
					gain := baseline-edge_cut(work, nets, degrees, net_count)
					work[a] = 0; work[b] = 1
					if gain > pair_gain { pair_gain = gain; chosen_a = a; chosen_b = b }
				}
			}
			selected_a[step] = chosen_a; selected_b[step] = chosen_b
			work[chosen_a] = 1; work[chosen_b] = 0
			for i in 0..<count_a {
				if remaining_a[i] == chosen_a {
					for j in i..<count_a-1 { remaining_a[j] = remaining_a[j+1] }
					count_a -= 1; break
				}
			}
			for i in 0..<count_b {
				if remaining_b[i] == chosen_b {
					for j in i..<count_b-1 { remaining_b[j] = remaining_b[j+1] }
					count_b -= 1; break
				}
			}
			cumulative_gain += pair_gain
			if cumulative_gain > best_gain { best_gain = cumulative_gain; best_prefix = step+1 }
		}
		if best_gain <= 0 do break
		next_a: [MAX_MODULES]int
		next_b: [MAX_MODULES]int
		for i in 0..<best_prefix { next_a[i] = selected_b[i]; next_b[i] = selected_a[i] }
		for i in best_prefix..<half { next_a[i] = selected_a[i]; next_b[i] = selected_b[i] }
		order_a = next_a; order_b = next_b
		for i in 0..<half { side[order_a[i]] = 0; side[order_b[i]] = 1 }
		accepted_passes += 1
	}
	mask: i64 = 0
	for i in 0..<modules { if side[i] == 0 { mask |= i64(1)<<i64(i) } }
	return mask + (i64(edge_cut(side, nets, degrees, net_count))<<8) +
		(i64(net_cut(side, nets, degrees, net_count))<<17) + (i64(accepted_passes)<<22)
}
