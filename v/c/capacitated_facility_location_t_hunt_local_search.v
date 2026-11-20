const max_n = 4
const max_f = 3
const max_initial_copies = 4
const max_copies = 644
const max_candidate_copies = 648
const max_p = 7
const max_parseable = 63
const max_output = 5208
const neg_inf = i64(-2305843009213693952)

fn put_word(mut output []u8, at int, value i64) {
	mut bits := u64(value)
	for b in 0 .. 8 {
		output[at + b] = u8(bits & 255)
		bits >>= 8
	}
}

fn insert_type(mut types []i64, kind i64) {
	types << kind
	mut at := types.len - 1
	for at > 0 && types[at - 1] > kind {
		types[at] = types[at - 1]
		at--
	}
	types[at] = kind
}

fn assign_state(n int, f int, d [][]i64, fees []i64, caps []i64, types []i64) (i64, []i64) {
	mut multiplicity := []int{len: f}
	for kind in types { multiplicity[int(kind)]++ }
	mut combinations := 1
	for _ in 0 .. n { combinations *= f }
	mut best_service := i64(9223372036854775807)
	mut best_types := []int{len: n}
	for code in 0 .. combinations {
		mut remainder := code
		mut candidate := []int{len: n}
		mut loads := []int{len: f}
		mut service := i64(0)
		for offset in 0 .. n {
			client := n - 1 - offset
			kind := remainder % f
			remainder /= f
			candidate[client] = kind
			loads[kind]++
			service += d[client][n + kind]
		}
		mut feasible := true
		for kind in 0 .. f {
			if loads[kind] > multiplicity[kind] * int(caps[kind]) { feasible = false }
		}
		if feasible && service < best_service {
			best_service = service
			for client in 0 .. n { best_types[client] = candidate[client] }
		}
	}
	mut assignment := []i64{len: n, init: -1}
	mut copy_loads := []int{len: types.len}
	for client in 0 .. n {
		for copy in 0 .. types.len {
			kind := int(types[copy])
			if assignment[client] == -1 && kind == best_types[client] && copy_loads[copy] < int(caps[kind]) {
				assignment[client] = i64(copy)
				copy_loads[copy]++
			}
		}
	}
	mut total := best_service
	for kind in types { total += fees[int(kind)] }
	return total, assignment
}

fn t_hunt(n int, f int, d [][]i64, fees []i64, caps []i64, types []i64,
	assignment []i64, target int, copies_added int) (i64, []bool) {
	let copies := types.len
	mut loads := []int{len: copies}
	mut profits := []i64{len: copies}
	let points := n + f
	for copy in 0 .. copies { profits[copy] = fees[int(types[copy])] }
	for client in 0 .. n {
		let copy := int(assignment[client])
		let old_type := int(types[copy])
		loads[copy]++
		profits[copy] += d[client][n + old_type] - d[client][n + target]
	}
	mut limit := copies_added * int(caps[target])
	if limit > n { limit = n }
	mut dp := []i64{len: limit + 1, init: neg_inf}
	dp[0] = 0
	mut take := [][]bool{len: copies, init: []bool{len: limit + 1}}
	for copy in 0 .. copies {
		mut next := dp.clone()
		for weight in 0 .. limit + 1 { take[copy][weight] = false }
		for weight in 0 .. limit + 1 {
			new_weight := weight + loads[copy]
			if dp[weight] != neg_inf && new_weight <= limit {
				value := dp[weight] + profits[copy]
				if value > next[new_weight] {
					next[new_weight] = value
					take[copy][new_weight] = true
				}
			}
		}
		dp = next
	}
	mut best_profit := neg_inf
	mut best_weight := 0
	for weight in 0 .. limit + 1 {
		if dp[weight] > best_profit { best_profit = dp[weight]; best_weight = weight }
	}
	mut selected := []bool{len: copies}
	mut used := best_weight
	for offset in 0 .. copies {
		let copy := copies - 1 - offset
		if take[copy][used] { selected[copy] = true; used -= loads[copy] }
	}
	return best_profit, selected
}

@[export: 'capacitated_facility_location_t_hunt_local_search']
pub fn capacitated_facility_location_t_hunt_local_search(input &i64, length usize,
	output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 10 || length > max_parseable { return -1 }
		nr, fr, qr := input[0], input[1], input[2]
		if nr < 1 || nr > max_n || fr < 1 || fr > max_f || qr < 1 || qr > max_initial_copies { return -1 }
		n, f, q := int(nr), int(fr), int(qr)
		points := n + f
		if length != usize(3 + points * points + 2 * f + q) { return -1 }
		mut d := [][]i64{len: max_p, init: []i64{len: max_p}}
		mut fees := []i64{len: max_f}
		mut caps := []i64{len: max_f}
		mut types := []i64{cap: max_candidate_copies}
		mut at := 3
		for i in 0 .. points {
			for j in 0 .. points {
				value := input[at]
				at++
				if value < 0 || value > 20 { return -1 }
				d[i][j] = value
			}
		}
		for i in 0 .. points {
			if d[i][i] != 0 { return -1 }
			for j in 0 .. points {
				if i != j && d[i][j] == 0 { return -1 }
				if d[i][j] != d[j][i] { return -1 }
				for k in 0 .. points { if d[i][j] > d[i][k] + d[k][j] { return -1 } }
			}
		}
		for kind in 0 .. f {
			fees[kind] = input[at]
			at++
			if fees[kind] < 0 || fees[kind] > 20 { return -1 }
		}
		for kind in 0 .. f {
			caps[kind] = input[at]
			at++
			if caps[kind] < 1 || caps[kind] > nr { return -1 }
		}
		mut total_capacity := 0
		for _ in 0 .. q {
			kind := input[at]
			at++
			if kind < 0 || kind >= fr { return -1 }
			types << kind
			total_capacity += int(caps[int(kind)])
		}
		if total_capacity < n { return -1 }
		for i in 1 .. types.len {
			value := types[i]
			mut j := i
			for j > 0 && types[j - 1] > value { types[j] = types[j - 1]; j-- }
			types[j] = value
		}
		mut current, mut assignment := assign_state(n, f, d, fees, caps, types)
		mut steps := 0
		for steps < 160 {
			mut moved := false
			for target in 0 .. f {
				mut candidate_types := types.clone()
				insert_type(mut candidate_types, i64(target))
				added_cost, added_assignment := assign_state(n, f, d, fees, caps, candidate_types)
				if added_cost < current {
					types = candidate_types
					current = added_cost
					assignment = added_assignment
					steps++
					moved = true
					break
				}
				for copies_added in 1 .. n + 1 {
					profit, selected := t_hunt(n, f, d, fees, caps, types, assignment, target, copies_added)
					if profit <= i64(copies_added) * fees[target] { continue }
					mut next_types := []i64{cap: types.len + copies_added}
					for copy in 0 .. types.len { if !selected[copy] { next_types << types[copy] } }
					for _ in 0 .. copies_added { insert_type(mut next_types, i64(target)) }
					next_cost, next_assignment := assign_state(n, f, d, fees, caps, next_types)
					if next_cost < current {
						types = next_types
						current = next_cost
						assignment = next_assignment
						steps++
						moved = true
						break
					}
				}
				if moved { break }
			}
			if !moved { break }
		}
		let bytes := 8 * (3 + types.len + n)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := []u8{len: bytes}
		put_word(mut staged, 0, current)
		put_word(mut staged, 8, i64(steps))
		put_word(mut staged, 16, i64(types.len))
		mut out_at := 24
		for kind in types { put_word(mut staged, out_at, kind); out_at += 8 }
		for client in 0 .. n { put_word(mut staged, out_at, assignment[client]); out_at += 8 }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
