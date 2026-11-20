module cactus_stack_branch_trace

fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'cactus_stack_branch_trace']
pub fn cactus_stack_branch_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 146 { return -1 }
	qraw := unsafe { input[0] }
	if qraw < 0 || qraw > 48 || int(length) != 1 + 3 * int(qraw) { return -1 }
	q := int(qraw)
	for i in 0 .. q {
		op := unsafe { input[1 + 3*i] }; a := unsafe { input[2 + 3*i] }; b := unsafe { input[3 + 3*i] }
		if op == 0 { if a < 0 || a >= 8 || b < -1000 || b > 1000 { return -1 }
		} else if op >= 1 && op <= 3 { if a < 0 || a >= 8 || b != 0 { return -1 }
		} else if op == 4 { if a < 0 || a >= 8 || b < 0 || b >= 8 { return -1 }
		} else { return -1 }
	}

	mut node_value := [48]i64{}
	mut node_next := [48]int{}
	mut node_kind := [48]int{}
	mut node_live := [48]bool{}
	mut heads := [8]int{}
	mut branch_child := [8]int{}
	mut attached_owner := [8]int{}
	mut wrapper_for_child := [8]int{}
	mut statuses := [48]i64{}
	mut results := [48]i64{}
	for h in 0 .. 8 { heads[h] = -1; branch_child[h] = -1; attached_owner[h] = -1; wrapper_for_child[h] = -1 }
	mut node_count := 0

	for i in 0 .. q {
		op := int(unsafe { input[1 + 3*i] }); a := int(unsafe { input[2 + 3*i] }); b := unsafe { input[3 + 3*i] }
		mut head := heads[a]
		for head >= 0 && node_kind[head] == 1 && !node_live[head] { head = node_next[head] }
		heads[a] = head; statuses[i] = 1
		if op == 0 {
			node_value[node_count] = b; node_next[node_count] = head; node_kind[node_count] = 0; node_live[node_count] = false
			heads[a] = node_count; node_count++
		} else if op == 1 {
			if head < 0 || (node_kind[head] == 1 && node_live[head]) { statuses[i] = 0
			} else {
				results[i] = node_value[head]
				mut next_head := node_next[head]
				for next_head >= 0 && node_kind[next_head] == 1 && !node_live[next_head] { next_head = node_next[next_head] }
				heads[a] = next_head
				if next_head < 0 && attached_owner[a] >= 0 {
					owner := attached_owner[a]; node_live[wrapper_for_child[a]] = false
					branch_child[owner] = -1; attached_owner[a] = -1; wrapper_for_child[a] = -1
				}
			}
		} else if op == 2 {
			mut top := head
			for top >= 0 && node_kind[top] == 1 {
				top = node_next[top]
				for top >= 0 && node_kind[top] == 1 && !node_live[top] { top = node_next[top] }
			}
			if top < 0 { statuses[i] = 0 } else { results[i] = node_value[top] }
		} else if op == 3 {
			if head >= 0 && node_kind[head] == 1 && node_live[head] { results[i] = 1 }
		} else {
			child := int(b)
			mut child_head := heads[child]
			for child_head >= 0 && node_kind[child_head] == 1 && !node_live[child_head] { child_head = node_next[child_head] }
			heads[child] = child_head
			mut owner_top := head
			for owner_top >= 0 && node_kind[owner_top] == 1 {
				owner_top = node_next[owner_top]
				for owner_top >= 0 && node_kind[owner_top] == 1 && !node_live[owner_top] { owner_top = node_next[owner_top] }
			}
			if a == child || owner_top < 0 || attached_owner[a] >= 0 || branch_child[a] >= 0 || attached_owner[child] >= 0 || branch_child[child] >= 0 { return -1 }
			if child_head < 0 { results[i] = 0
			} else {
				node_value[node_count] = 0; node_next[node_count] = head; node_kind[node_count] = 1; node_live[node_count] = true
				wrapper := node_count; node_count++; heads[a] = wrapper
				branch_child[a] = child; attached_owner[child] = a; wrapper_for_child[child] = wrapper; results[i] = 1
			}
		}
	}

	bytes := 16 * q
	if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
	for i in 0 .. q { store_le(mut output, 16*i, statuses[i]); store_le(mut output, 16*i+8, results[i]) }
	return i64(bytes)
}
