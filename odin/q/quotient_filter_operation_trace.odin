package quotient_filter_operation_trace

import "core:c"

SLOTS :: 8
MAX_OPS :: 32
MAX_ITEMS :: 6

next_slot :: proc(i: int) -> int { return (i + 1) % SLOTS }
prev_slot :: proc(i: int) -> int { return (i + SLOTS - 1) % SLOTS }

empty_slot :: proc(i: int, rem: [^]u8, occ, cont, shifted: [^]bool) -> bool {
	return rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i]
}

find_run :: proc(q: int, occ, cont, shifted: [^]bool) -> int {
	if !occ[q] do return -2
	bucket := q
	steps := 0
	for shifted[bucket] && steps < SLOTS {
		bucket = prev_slot(bucket)
		steps += 1
	}
	if steps >= SLOTS do return -1
	slot := bucket
	for bucket != q {
		slot = next_slot(slot)
		steps = 0
		for cont[slot] && steps < SLOTS {
			slot = next_slot(slot)
			steps += 1
		}
		if steps >= SLOTS do return -1
		bucket = next_slot(bucket)
		steps = 0
		for !occ[bucket] && steps < SLOTS {
			bucket = next_slot(bucket)
			steps += 1
		}
		if steps >= SLOTS do return -1
	}
	return slot
}

find_insert_position :: proc(q: int, occ, cont, shifted: [^]bool) -> int {
    bucket := q
    steps := 0
    for shifted[bucket] && steps < SLOTS { bucket = prev_slot(bucket); steps += 1 }
    if steps >= SLOTS do return -1
    slot := bucket
    for bucket != q {
        steps = 0
        for {
            slot = next_slot(slot)
            steps += 1
            if !cont[slot] || steps >= SLOTS do break
        }
        if steps >= SLOTS do return -1
        bucket = next_slot(bucket)
        steps = 0
        for bucket != q && !occ[bucket] && steps < SLOTS {
            bucket = next_slot(bucket)
            steps += 1
        }
        if steps >= SLOTS do return -1
    }
    return slot
}

next_occupied :: proc(q: int, occ: [^]bool) -> int {
    bucket := next_slot(q)
    for i := 0; i < SLOTS; i += 1 {
        if occ[bucket] do return bucket
        bucket = next_slot(bucket)
    }
    return -1
}

insert_at :: proc(position, q: int, r: u8, has_run: bool, run_start: int,
		rem: [^]u8, occ, cont, shifted: [^]bool) -> bool {
    new_cont := has_run && position != run_start
    if has_run && position == run_start do cont[position] = true
    empty := position
    found_empty := false
    for i := 0; i < SLOTS; i += 1 {
        if empty_slot(empty, rem, occ, cont, shifted) { found_empty = true; break }
        empty = next_slot(empty)
    }
    if !found_empty do return false
    slot := empty
    for slot != position {
        previous := prev_slot(slot)
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

@(export)
quotient_filter_operation_trace :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 66 do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_OPS do return -1
	count := int(raw_count)
	if length != c.size_t(1 + 2 * count) do return -1
	for op := 0; op < count; op += 1 {
		opcode := input[1 + 2 * op]
		fp := input[2 + 2 * op]
		if opcode < 0 || opcode > 2 || fp < 0 || fp > 255 do return -1
	}
	if output == nil || capacity < c.size_t(count) do return -2

	rem: [SLOTS]u8
	occ, cont, shifted: [SLOTS]bool
	statuses: [MAX_OPS]u8
	for i := 0; i < SLOTS; i += 1 { rem[i] = 0; occ[i] = false; cont[i] = false; shifted[i] = false }
	total := 0
	for op := 0; op < count; op += 1 {
		opcode := input[1 + 2 * op]
		fp := int(input[2 + 2 * op])
		q := fp >> 5
		r := u8(fp & 31)
		if opcode == 0 {
			if total == MAX_ITEMS { statuses[op] = 2; continue }
			position := find_run(q, &occ[0], &cont[0], &shifted[0])
			if position == -1 do return -1
			run_start := position
			if position >= 0 {
				for n := 0; n < SLOTS; n += 1 {
					if rem[position] > r do break
					next := next_slot(position)
					position = next
					if !cont[next] do break
				}
			} else if !empty_slot(q, &rem[0], &occ[0], &cont[0], &shifted[0]) {
				position = find_insert_position(q, &occ[0], &cont[0], &shifted[0])
				if position < 0 do return -1
			} else { position = q }
			has_run := occ[q]
			if !insert_at(position, q, r, has_run, run_start, &rem[0], &occ[0], &cont[0], &shifted[0]) do return -1
			total += 1
			statuses[op] = 1
		} else if opcode == 1 {
			position := find_run(q, &occ[0], &cont[0], &shifted[0])
			if position == -1 do return -1
			found := false
			if position >= 0 {
				for n := 0; n < SLOTS; n += 1 {
					if rem[position] == r { found = true; break }
					if rem[position] > r do break
					next := next_slot(position)
					if !cont[next] do break
					position = next
				}
			}
			if found { statuses[op] = 1 } else { statuses[op] = 0 }
		} else {
			position := find_run(q, &occ[0], &cont[0], &shifted[0])
			if position == -1 do return -1
			removed := false
			if position >= 0 {
				for n := 0; n < SLOTS; n += 1 {
					if rem[position] == r { removed = true; break }
					if rem[position] > r do break
					next := next_slot(position)
					if !cont[next] do break
					position = next
				}
			}
			if !removed { statuses[op] = 0; continue }
			was_run_start := !cont[position]
			following := next_slot(position)
			has_more_same := !empty_slot(following, &rem[0], &occ[0], &cont[0], &shifted[0]) && cont[following]
			if was_run_start && !has_more_same do occ[q] = false
			rem[position] = 0
			cont[position] = false
			shifted[position] = false
			hole := position
			current_q := q
			first_shift := true
			for n := 0; n < SLOTS - 1; n += 1 {
				next := next_slot(hole)
				if empty_slot(next, &rem[0], &occ[0], &cont[0], &shifted[0]) || !shifted[next] do break
				source_cont := cont[next]
				promote := first_shift && was_run_start && has_more_same
				if !source_cont && !promote {
					current_q = next_occupied(current_q, &occ[0])
					if current_q < 0 do return -1
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
			total -= 1
			statuses[op] = 1
		}
	}
	for i := 0; i < count; i += 1 { output[i] = statuses[i] }
	return i64(count)
}
