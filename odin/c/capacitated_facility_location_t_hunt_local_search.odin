package capacitated_facility_location_t_hunt_local_search

import "core:c"

MAX_N :: 4
MAX_F :: 3
MAX_INITIAL_COPIES :: 4
MAX_COPIES :: 644
MAX_CANDIDATE_COPIES :: 648
MAX_P :: 7
MAX_PARSEABLE :: 63
MAX_OUTPUT :: 5208
NEG_INF :: i64(-2305843009213693952)

put_word :: proc "contextless" (out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 {
		out[at+b] = u8(bits & 255)
		bits >>= 8
	}
}

insert_type :: proc(types: [^]i64, copies: ^int, kind: i64) {
	at := copies^
	for at > 0 && types[at-1] > kind {
		types[at] = types[at-1]
		at -= 1
	}
	types[at] = kind
	copies^ += 1
}

assign_state :: proc(n, f: int, d: ^([MAX_P][MAX_P]i64),
	fees, caps: ^([MAX_F]i64), types: [^]i64, copies: int,
	assignment: ^([MAX_N]i64)) -> i64 {
	multiplicity: [MAX_F]int
	for copy := 0; copy < copies; copy += 1 {
		multiplicity[int(types[copy])] += 1
	}
	combinations := 1
	for _ := 0; _ < n; _ += 1 {
		combinations *= f
	}
	best_service := i64(9223372036854775807)
	best_types: [MAX_N]int
	for code := 0; code < combinations; code += 1 {
		candidate: [MAX_N]int
		loads: [MAX_F]int
		remainder := code
		service := i64(0)
		for offset := 0; offset < n; offset += 1 {
			client := n - 1 - offset
			kind := remainder % f
			remainder /= f
			candidate[client] = kind
			loads[kind] += 1
			service += d[client][n+kind]
		}
		feasible := true
		for kind := 0; kind < f; kind += 1 {
			if loads[kind] > multiplicity[kind]*int(caps[kind]) {
				feasible = false
			}
		}
		if feasible && service < best_service {
			best_service = service
			for client := 0; client < n; client += 1 {
				best_types[client] = candidate[client]
			}
		}
	}
	copy_loads: [MAX_CANDIDATE_COPIES]int
	for client := 0; client < n; client += 1 {
		assignment^[client] = -1
		for copy := 0; copy < copies; copy += 1 {
			kind := int(types[copy])
			if assignment^[client] == -1 && kind == best_types[client] && copy_loads[copy] < int(caps[kind]) {
				assignment^[client] = i64(copy)
				copy_loads[copy] += 1
			}
		}
	}
	total := best_service
	for copy := 0; copy < copies; copy += 1 {
		total += fees[int(types[copy])]
	}
	return total
}

t_hunt :: proc(n, f: int, d: ^([MAX_P][MAX_P]i64),
	fees, caps: ^([MAX_F]i64), types: [^]i64, copies: int,
	assignment: ^([MAX_N]i64), target, copies_added: int,
	selected: ^([MAX_COPIES]bool)) -> i64 {
	loads: [MAX_COPIES]int
	profits: [MAX_COPIES]i64
	for copy := 0; copy < copies; copy += 1 {
		profits[copy] = fees[int(types[copy])]
	}
	for client := 0; client < n; client += 1 {
		copy := int(assignment^[client])
		old_type := int(types[copy])
		loads[copy] += 1
		profits[copy] += d[client][n+old_type] - d[client][n+target]
	}
	limit := copies_added*int(caps[target])
	if limit > n {
		limit = n
	}
	dp: [MAX_N+1]i64
	for weight := 0; weight <= MAX_N; weight += 1 {
		dp[weight] = NEG_INF
	}
	dp[0] = 0
	take: [MAX_COPIES][MAX_N+1]bool
	for copy := 0; copy < copies; copy += 1 {
		next := dp
		for weight := 0; weight <= limit; weight += 1 {
			take[copy][weight] = false
		}
		for weight := 0; weight <= limit; weight += 1 {
			new_weight := weight + loads[copy]
			if dp[weight] != NEG_INF && new_weight <= limit {
				value := dp[weight] + profits[copy]
				if value > next[new_weight] {
					next[new_weight] = value
					take[copy][new_weight] = true
				}
			}
		}
		dp = next
	}
	best_profit := NEG_INF
	best_weight := 0
	for weight := 0; weight <= limit; weight += 1 {
		if dp[weight] > best_profit {
			best_profit = dp[weight]
			best_weight = weight
		}
	}
	for copy := 0; copy < copies; copy += 1 {
		selected^[copy] = false
	}
	used := best_weight
	for offset := 0; offset < copies; offset += 1 {
		copy := copies - 1 - offset
		if take[copy][used] {
			selected^[copy] = true
			used -= loads[copy]
		}
	}
	return best_profit
}

@(export)
capacitated_facility_location_t_hunt_local_search :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 10 || length > MAX_PARSEABLE do return -1
	nr, fr, qr := input[0], input[1], input[2]
	if nr < 1 || nr > MAX_N || fr < 1 || fr > MAX_F || qr < 1 || qr > MAX_INITIAL_COPIES do return -1
	n, f, q := int(nr), int(fr), int(qr)
	points := n + f
	if length != c.size_t(3+points*points+2*f+q) do return -1
	d: [MAX_P][MAX_P]i64
	fees: [MAX_F]i64
	caps: [MAX_F]i64
	types: [MAX_CANDIDATE_COPIES]i64
	at := 3
	for i := 0; i < points; i += 1 {
		for j := 0; j < points; j += 1 {
			value := input[at]
			at += 1
			if value < 0 || value > 20 do return -1
			d[i][j] = value
		}
	}
	for i := 0; i < points; i += 1 {
		if d[i][i] != 0 do return -1
		for j := 0; j < points; j += 1 {
			if i != j && d[i][j] == 0 do return -1
			if d[i][j] != d[j][i] do return -1
			for k := 0; k < points; k += 1 {
				if d[i][j] > d[i][k]+d[k][j] do return -1
			}
		}
	}
	for kind := 0; kind < f; kind += 1 {
		fees[kind] = input[at]
		at += 1
		if fees[kind] < 0 || fees[kind] > 20 do return -1
	}
	for kind := 0; kind < f; kind += 1 {
		caps[kind] = input[at]
		at += 1
		if caps[kind] < 1 || caps[kind] > nr do return -1
	}
	total_capacity := 0
	for copy := 0; copy < q; copy += 1 {
		kind := input[at]
		at += 1
		if kind < 0 || kind >= fr do return -1
		types[copy] = kind
		total_capacity += int(caps[int(kind)])
	}
	if total_capacity < n do return -1
	copies := q
	for i := 1; i < copies; i += 1 {
		value := types[i]
		j := i
		for j > 0 && types[j-1] > value {
			types[j] = types[j-1]
			j -= 1
		}
		types[j] = value
	}
	assignment: [MAX_N]i64
	current := assign_state(n, f, &d, &fees, &caps, &types[0], copies, &assignment)
	steps := 0
	for steps < 160 {
		moved := false
		for target := 0; target < f; target += 1 {
			candidate_types := types
			candidate_copies := copies
			insert_type(&candidate_types[0], &candidate_copies, i64(target))
			candidate_assignment: [MAX_N]i64
			added_cost := assign_state(n, f, &d, &fees, &caps, &candidate_types[0], candidate_copies, &candidate_assignment)
			if added_cost < current {
				types = candidate_types
				copies = candidate_copies
				current = added_cost
				assignment = candidate_assignment
				steps += 1
				moved = true
				break
			}
			selected: [MAX_COPIES]bool
			for copies_added := 1; copies_added <= n; copies_added += 1 {
				profit := t_hunt(n, f, &d, &fees, &caps, &types[0], copies,
					&assignment, target, copies_added, &selected)
				if profit <= i64(copies_added)*fees[target] do continue
				drop_count := 0
				for copy := 0; copy < copies; copy += 1 {
					if !selected[copy] {
						candidate_types[drop_count] = types[copy]
						drop_count += 1
					}
				}
				candidate_copies = drop_count
				for _ := 0; _ < copies_added; _ += 1 {
					insert_type(&candidate_types[0], &candidate_copies, i64(target))
				}
				next_cost := assign_state(n, f, &d, &fees, &caps, &candidate_types[0], candidate_copies, &candidate_assignment)
				if next_cost < current {
					types = candidate_types
					copies = candidate_copies
					current = next_cost
					assignment = candidate_assignment
					steps += 1
					moved = true
					break
				}
			}
			if moved do break
		}
		if !moved do break
	}
	words := 3+copies+n
	bytes := 8*words
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_word(output, 0, current)
	put_word(output, 8, i64(steps))
	put_word(output, 16, i64(copies))
	at = 24
	for copy := 0; copy < copies; copy += 1 {
		put_word(output, at, types[copy])
		at += 8
	}
	for client := 0; client < n; client += 1 {
		put_word(output, at, assignment[client])
		at += 8
	}
	return i64(bytes)
}
