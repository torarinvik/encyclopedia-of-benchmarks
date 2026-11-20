package oscillating_merge_sort

import "core:c"

MAX_VALUES :: 1024
MAX_PARTS :: 2
INITIAL_RUN_SIZE :: 16

build_run :: proc(values: [^]i64, value_count, run_size, merge_inputs,
		first_run, run_count: int, ascending: bool, output: [^]i64) -> int {
	if run_count == 1 {
		start := first_run * run_size
		length := min(run_size, value_count - start)
		for i := 0; i < length; i += 1 { output[i] = values[start + i] }
		for i := 1; i < length; i += 1 {
			value := output[i]
			position := i
			for position > 0 && (if ascending { value < output[position - 1] } else { value > output[position - 1] }) {
				output[position] = output[position - 1]
				position -= 1
			}
			output[position] = value
		}
		return length
	}

	children: [MAX_PARTS][MAX_VALUES]i64
	lengths: [MAX_PARTS]int
	positions: [MAX_PARTS]int
	quotient := run_count / merge_inputs
	remainder := run_count % merge_inputs
	next_run := first_run
	total := 0
	for lane := 0; lane < merge_inputs; lane += 1 {
		child_count := quotient
		if lane < remainder { child_count += 1 }
		if child_count == 0 { continue }
		lengths[lane] = build_run(values, value_count, run_size, merge_inputs,
			next_run, child_count, !ascending, &children[lane][0])
		next_run += child_count
		total += lengths[lane]
	}
	for out_index := 0; out_index < total; out_index += 1 {
		best_lane := MAX_PARTS
		best_value: i64 = 0
		for lane := 0; lane < merge_inputs; lane += 1 {
			if positions[lane] >= lengths[lane] { continue }
			candidate := children[lane][lengths[lane] - 1 - positions[lane]]
			if best_lane == MAX_PARTS || (if ascending { candidate < best_value } else { candidate > best_value }) {
				best_lane = lane
				best_value = candidate
			}
		}
		output[out_index] = best_value
		positions[best_lane] += 1
	}
	return total
}

@(export)
oscillating_merge_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length == 0 || length > c.size_t(MAX_VALUES) || values == nil do return
	count := int(length)
	sorted: [MAX_VALUES]i64
	run_count := (count + INITIAL_RUN_SIZE - 1) / INITIAL_RUN_SIZE
	_ = build_run(values, count, INITIAL_RUN_SIZE, MAX_PARTS, 0,
		run_count, true, &sorted[0])
	for i := 0; i < count; i += 1 { values[i] = sorted[i] }
}
