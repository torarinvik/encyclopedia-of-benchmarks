package job_scheduling_with_deadline

import "core:c"

MAX_INPUT :: 513
MAX_PROFIT :: i64(1_000_000)
PACK_BASE :: i64(4_294_967_296)

@(export)
job_scheduling_with_deadline :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 1 || length > MAX_INPUT do return -1
	count_value := packed[0]
	if count_value < 0 || count_value > 128 || length != c.size_t(1 + count_value * 4) do return -1
	count := int(count_value)

	ids: [128]i64
	arrivals: [128]i64
	deadlines: [128]i64
	profits: [128]i64
	max_deadline := i64(0)
	for i in 0..<count {
		base := 1 + i * 4
		ids[i] = packed[base]
		arrivals[i] = packed[base + 1]
		deadlines[i] = packed[base + 2]
		profits[i] = packed[base + 3]
		if ids[i] < 0 || ids[i] > 2_147_483_647 ||
			arrivals[i] < 1 || arrivals[i] > 32 ||
			deadlines[i] < 1 || deadlines[i] > 32 ||
			profits[i] < -MAX_PROFIT || profits[i] > MAX_PROFIT do return -1
		for previous in 0..<i {
			if ids[previous] == ids[i] do return -1
		}
		if deadlines[i] > max_deadline do max_deadline = deadlines[i]
	}

	// Stable insertion sort retains input order for equal profits.
	for i in 1..<count {
		key_id, key_arrival, key_deadline, key_profit :=
			ids[i], arrivals[i], deadlines[i], profits[i]
		position := i
		for position > 0 && profits[position - 1] < key_profit {
			ids[position] = ids[position - 1]
			arrivals[position] = arrivals[position - 1]
			deadlines[position] = deadlines[position - 1]
			profits[position] = profits[position - 1]
			position -= 1
		}
		ids[position] = key_id
		arrivals[position] = key_arrival
		deadlines[position] = key_deadline
		profits[position] = key_profit
	}

	occupied: [32]bool
	scheduled := i64(0)
	total_profit := i64(0)
	for i in 0..<count {
		if arrivals[i] > deadlines[i] do continue
		last_slot := deadlines[i] - 1
		if last_slot > max_deadline - 1 do last_slot = max_deadline - 1
		for slot := last_slot; slot >= arrivals[i] - 1; slot -= 1 {
			index := int(slot)
			if !occupied[index] {
				occupied[index] = true
				scheduled += 1
				total_profit += profits[i]
				break
			}
		}
	}
	low_word := total_profit
	if low_word < 0 do low_word += PACK_BASE
	return scheduled * PACK_BASE + low_word
}
