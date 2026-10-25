module main

const max_modules = 8
const max_nets = 16
const max_input = 146

fn edge_cut(side [max_modules]int, nets [max_nets][max_modules]int, degrees [max_nets]int, net_count int) int {
	mut total := 0
	for net in 0 .. net_count {
		for i in 0 .. degrees[net] {
			for j in i + 1 .. degrees[net] {
				if side[nets[net][i]] != side[nets[net][j]] { total++ }
			}
		}
	}
	return total
}

fn net_cut(side [max_modules]int, nets [max_nets][max_modules]int, degrees [max_nets]int, net_count int) int {
	mut total := 0
	for net in 0 .. net_count {
		first := side[nets[net][0]]
		for i in 1 .. degrees[net] {
			if side[nets[net][i]] != first { total++; break }
		}
	}
	return total
}

@[export: 'ptrdist_ks']
pub fn ptrdist_ks(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	module_value := unsafe { input[0] }
	net_value := unsafe { input[1] }
	if module_value < 2 || module_value > max_modules || module_value % 2 != 0 || net_value < 0 || net_value > max_nets { return -1 }
	modules := int(module_value)
	net_count := int(net_value)
	mut nets := [max_nets][max_modules]int{}
	mut degrees := [max_nets]int{}
	mut cursor := 2
	for net in 0 .. net_count {
		if cursor >= int(length) { return -1 }
		degree_value := unsafe { input[cursor] }
		cursor++
		if degree_value < 2 || degree_value > module_value || cursor + int(degree_value) > int(length) { return -1 }
		degree := int(degree_value)
		degrees[net] = degree
		for i in 0 .. degree {
			member_value := unsafe { input[cursor] }
			cursor++
			if member_value < 0 || member_value >= module_value { return -1 }
			member := int(member_value)
			for j in 0 .. i { if nets[net][j] == member { return -1 } }
			nets[net][i] = member
		}
	}
	if cursor != int(length) { return -1 }

	half := modules / 2
	mut order_a := [max_modules]int{}
	mut order_b := [max_modules]int{}
	mut side := [max_modules]int{}
	for i in 0 .. half { order_a[i] = i; order_b[i] = half + i; side[i] = 0; side[half + i] = 1 }
	mut accepted_passes := 0
	for {
		mut work := side
		mut remaining_a := order_a
		mut remaining_b := order_b
		mut selected_a := [max_modules]int{}
		mut selected_b := [max_modules]int{}
		mut count_a := half
		mut count_b := half
		mut cumulative_gain := 0
		mut best_gain := -2147483647
		mut best_prefix := 0
		for step in 0 .. half {
			baseline := edge_cut(work, nets, degrees, net_count)
			mut pair_gain := -2147483647
			mut chosen_a := -1
			mut chosen_b := -1
			for ai in 0 .. count_a {
				a := remaining_a[ai]
				for bi in 0 .. count_b {
					b := remaining_b[bi]
					work[a] = 1; work[b] = 0
					gain := baseline - edge_cut(work, nets, degrees, net_count)
					work[a] = 0; work[b] = 1
					if gain > pair_gain { pair_gain = gain; chosen_a = a; chosen_b = b }
				}
			}
			selected_a[step] = chosen_a; selected_b[step] = chosen_b
			work[chosen_a] = 1; work[chosen_b] = 0
			mut i := 0
			for i < count_a {
				if remaining_a[i] == chosen_a {
					for j in i .. count_a - 1 { remaining_a[j] = remaining_a[j + 1] }
					count_a--; break
				}
				i++
			}
			i = 0
			for i < count_b {
				if remaining_b[i] == chosen_b {
					for j in i .. count_b - 1 { remaining_b[j] = remaining_b[j + 1] }
					count_b--; break
				}
				i++
			}
			cumulative_gain += pair_gain
			if cumulative_gain > best_gain { best_gain = cumulative_gain; best_prefix = step + 1 }
		}
		if best_gain <= 0 { break }
		mut next_a := [max_modules]int{}
		mut next_b := [max_modules]int{}
		for i in 0 .. best_prefix { next_a[i] = selected_b[i]; next_b[i] = selected_a[i] }
		for i in best_prefix .. half { next_a[i] = selected_a[i]; next_b[i] = selected_b[i] }
		order_a = next_a; order_b = next_b
		for i in 0 .. half { side[order_a[i]] = 0; side[order_b[i]] = 1 }
		accepted_passes++
	}
	mut mask := i64(0)
	for i in 0 .. modules { if side[i] == 0 { mask |= i64(1) << i } }
	return mask + (i64(edge_cut(side, nets, degrees, net_count)) << 8) +
		(i64(net_cut(side, nets, degrees, net_count)) << 17) + (i64(accepted_passes) << 22)
}
