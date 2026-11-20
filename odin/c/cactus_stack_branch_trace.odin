package cactus_stack_branch_trace

import "core:c"

@(export)
cactus_stack_branch_trace :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 146 do return -1
	qv := input[0]
	if qv < 0 || qv > 48 || length != c.size_t(1 + 3*qv) do return -1
	q := int(qv)
	for i := 0; i < q; i += 1 {
		op, a, b := input[1+3*i], input[2+3*i], input[3+3*i]
		if op == 0 { if a < 0 || a >= 8 || b < -1000 || b > 1000 do return -1
		} else if op >= 1 && op <= 3 { if a < 0 || a >= 8 || b != 0 do return -1
		} else if op == 4 { if a < 0 || a >= 8 || b < 0 || b >= 8 do return -1
		} else { return -1 }
	}

	var node_value: [48]i64
	var node_next: [48]int
	var node_kind: [48]int
	var node_live: [48]bool
	var heads: [8]int
	var branch_child: [8]int
	var attached_owner: [8]int
	var wrapper_for_child: [8]int
	var statuses: [48]i64
	var results: [48]i64
	for h := 0; h < 8; h += 1 {
		heads[h] = -1; branch_child[h] = -1; attached_owner[h] = -1; wrapper_for_child[h] = -1
	}
	node_count := 0
	for i := 0; i < q; i += 1 {
		op := int(input[1+3*i]); a := int(input[2+3*i]); b := input[3+3*i]
		head := heads[a]
		for head >= 0 && node_kind[head] == 1 && !node_live[head] { head = node_next[head] }
		heads[a] = head; statuses[i] = 1
		if op == 0 {
			node_value[node_count] = b; node_next[node_count] = head; node_kind[node_count] = 0
			node_live[node_count] = false; heads[a] = node_count; node_count += 1
		} else if op == 1 {
			if head < 0 || (node_kind[head] == 1 && node_live[head]) { statuses[i] = 0
			} else {
				results[i] = node_value[head]
				next_head := node_next[head]
				for next_head >= 0 && node_kind[next_head] == 1 && !node_live[next_head] { next_head = node_next[next_head] }
				heads[a] = next_head
				if next_head < 0 && attached_owner[a] >= 0 {
					owner := attached_owner[a]; node_live[wrapper_for_child[a]] = false
					branch_child[owner] = -1; attached_owner[a] = -1; wrapper_for_child[a] = -1
				}
			}
		} else if op == 2 {
			top := head
			for top >= 0 && node_kind[top] == 1 {
				top = node_next[top]
				for top >= 0 && node_kind[top] == 1 && !node_live[top] { top = node_next[top] }
			}
			if top < 0 { statuses[i] = 0 } else { results[i] = node_value[top] }
		} else if op == 3 {
			if head >= 0 && node_kind[head] == 1 && node_live[head] { results[i] = 1 }
		} else {
			child := int(b)
			child_head := heads[child]
			for child_head >= 0 && node_kind[child_head] == 1 && !node_live[child_head] { child_head = node_next[child_head] }
			heads[child] = child_head
			owner_top := head
			for owner_top >= 0 && node_kind[owner_top] == 1 {
				owner_top = node_next[owner_top]
				for owner_top >= 0 && node_kind[owner_top] == 1 && !node_live[owner_top] { owner_top = node_next[owner_top] }
			}
			if a == child || owner_top < 0 || attached_owner[a] >= 0 || branch_child[a] >= 0 || attached_owner[child] >= 0 || branch_child[child] >= 0 do return -1
			if child_head < 0 { results[i] = 0
			} else {
				node_value[node_count] = 0; node_next[node_count] = head; node_kind[node_count] = 1; node_live[node_count] = true
				wrapper := node_count; node_count += 1; heads[a] = wrapper
				branch_child[a] = child; attached_owner[child] = a; wrapper_for_child[child] = wrapper; results[i] = 1
			}
		}
	}

	bytes := 16*q
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < q; i += 1 { store_le(output, 16*i, statuses[i]); store_le(output, 16*i+8, results[i]) }
	return i64(bytes)
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for b := 0; b < 8; b += 1 { output[offset+b] = u8((bits >> u64(8*b)) & 255) }
}
