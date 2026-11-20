module quotient_filter_operation_trace

const slots = 8
const max_operations = 32
const max_items = 6

fn qf_next(i int) int { return (i + 1) % slots }
fn qf_prev(i int) int { return (i + slots - 1) % slots }

fn qf_empty(i int, rem [slots]u8, occ [slots]bool, cont [slots]bool, shifted [slots]bool) bool {
	return rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i]
}

fn qf_find_run(q int, occ [slots]bool, cont [slots]bool, shifted [slots]bool) int {
	if !occ[q] { return -2 }
	mut bucket := q
	mut steps := 0
	for shifted[bucket] && steps < slots { bucket = qf_prev(bucket); steps++ }
	if steps >= slots { return -1 }
	mut slot := bucket
	for bucket != q {
		slot = qf_next(slot)
		steps = 0
		for cont[slot] && steps < slots { slot = qf_next(slot); steps++ }
		if steps >= slots { return -1 }
		bucket = qf_next(bucket)
		steps = 0
		for !occ[bucket] && steps < slots { bucket = qf_next(bucket); steps++ }
		if steps >= slots { return -1 }
	}
	return slot
}

fn qf_find_insert_position(q int, occ [slots]bool, cont [slots]bool, shifted [slots]bool) int {
	mut bucket := q
	mut steps := 0
	for shifted[bucket] && steps < slots { bucket = qf_prev(bucket); steps++ }
	if steps >= slots { return -1 }
	mut slot := bucket
	for bucket != q {
		steps = 0
		for steps < slots {
			slot = qf_next(slot)
			steps++
			if !cont[slot] { break }
		}
		if steps >= slots { return -1 }
		bucket = qf_next(bucket)
		steps = 0
		for bucket != q && !occ[bucket] && steps < slots { bucket = qf_next(bucket); steps++ }
		if steps >= slots { return -1 }
	}
	return slot
}

fn qf_next_occupied(q int, occ [slots]bool) int {
	mut bucket := qf_next(q)
	for _ in 0 .. slots {
		if occ[bucket] { return bucket }
		bucket = qf_next(bucket)
	}
	return -1
}

fn qf_insert_at(position int, q int, r u8, has_run bool, run_start int,
		mut rem [slots]u8, mut occ [slots]bool, mut cont [slots]bool, mut shifted [slots]bool) bool {
	new_cont := has_run && position != run_start
	if has_run && position == run_start { cont[position] = true }
	mut empty := position
	mut found_empty := false
	for _ in 0 .. slots {
		if qf_empty(empty, rem, occ, cont, shifted) { found_empty = true; break }
		empty = qf_next(empty)
	}
	if !found_empty { return false }
	mut slot := empty
	for slot != position {
		previous := qf_prev(slot)
		rem[slot] = rem[previous]
		cont[slot] = cont[previous]
		shifted[slot] = true
		slot = previous
	}
	rem[position] = r
	cont[position] = new_cont
	shifted[position] = position != q
	occ[q] = true
	return true
}

@[export: 'quotient_filter_operation_trace']
pub fn quotient_filter_operation_trace(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 66 { return -1 }
		count64 := input[0]
		if count64 < 0 || count64 > max_operations || length != usize(1 + 2 * count64) { return -1 }
		count := int(count64)
		for op in 0 .. count {
			opcode := input[1 + 2 * op]
			fp := input[2 + 2 * op]
			if opcode < 0 || opcode > 2 || fp < 0 || fp > 255 { return -1 }
		}
		if output == nil || capacity < usize(count) { return -2 }

		mut rem := [slots]u8{}
		mut occ := [slots]bool{}
		mut cont := [slots]bool{}
		mut shifted := [slots]bool{}
		mut statuses := [max_operations]u8{}
		mut total := 0
		for op in 0 .. count {
			opcode := input[1 + 2 * op]
			fp := int(input[2 + 2 * op])
			q := fp >> 5
			r := u8(fp & 31)
			if opcode == 0 {
				if total == max_items { statuses[op] = 2; continue }
				mut position := qf_find_run(q, occ, cont, shifted)
				if position == -1 { return -1 }
				run_start := position
				has_run := position >= 0
				if position >= 0 {
					for _ in 0 .. slots {
						if rem[position] > r { break }
						next := qf_next(position)
						position = next
						if !cont[next] { break }
					}
				} else if !qf_empty(q, rem, occ, cont, shifted) {
					position = qf_find_insert_position(q, occ, cont, shifted)
					if position < 0 { return -1 }
				} else { position = q }
				mut actual_run_start := run_start
				if !has_run { actual_run_start = position }
				if !qf_insert_at(position, q, r, has_run, actual_run_start, mut rem, mut occ, mut cont, mut shifted) { return -1 }
				total++
				statuses[op] = 1
			} else if opcode == 1 {
				mut position := qf_find_run(q, occ, cont, shifted)
				if position == -1 { return -1 }
				mut found := false
				if position >= 0 {
					for _ in 0 .. slots {
						if rem[position] == r { found = true; break }
						if rem[position] > r { break }
						next := qf_next(position)
						if !cont[next] { break }
						position = next
					}
				}
				statuses[op] = if found { u8(1) } else { u8(0) }
			} else {
				mut position := qf_find_run(q, occ, cont, shifted)
				if position == -1 { return -1 }
				mut removed := false
				if position >= 0 {
					for _ in 0 .. slots {
						if rem[position] == r { removed = true; break }
						if rem[position] > r { break }
						next := qf_next(position)
						if !cont[next] { break }
						position = next
					}
				}
				if !removed { statuses[op] = 0; continue }
				was_run_start := !cont[position]
				following := qf_next(position)
				has_more_same := !qf_empty(following, rem, occ, cont, shifted) && cont[following]
				if was_run_start && !has_more_same { occ[q] = false }
				rem[position] = 0
				cont[position] = false
				shifted[position] = false
				mut hole := position
				mut current_q := q
				mut first_shift := true
				for _ in 0 .. slots - 1 {
					next := qf_next(hole)
					if qf_empty(next, rem, occ, cont, shifted) || !shifted[next] { break }
					source_cont := cont[next]
					promote := first_shift && was_run_start && has_more_same
					if !source_cont && !promote {
						current_q = qf_next_occupied(current_q, occ)
						if current_q < 0 { return -1 }
					}
					rem[hole] = rem[next]
					cont[hole] = !promote && source_cont
					shifted[hole] = cont[hole] || hole != current_q
					rem[next] = 0
					cont[next] = false
					shifted[next] = false
					hole = next
					first_shift = false
				}
				rem[hole] = 0
				cont[hole] = false
				shifted[hole] = false
				total--
				statuses[op] = 1
			}
		}
		for i in 0 .. count { output[i] = statuses[i] }
		return i64(count)
	}
}
