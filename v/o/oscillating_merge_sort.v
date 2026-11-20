module oscillating_merge_sort

const max_values = 1024
const max_parts = 2
const initial_run_size = 16

fn build_run(values &i64, value_count int, run_size int, merge_inputs int,
		first_run int, run_count int, ascending bool, mut output &i64) int {
	if run_count == 1 {
		start := first_run * run_size
		length := min(run_size, value_count - start)
		for i in 0 .. length { unsafe { output[i] = values[start + i] } }
		for i in 1 .. length {
			value := unsafe { output[i] }
			mut position := i
			for position > 0 {
				previous := unsafe { output[position - 1] }
				if ascending && value >= previous { break }
				if !ascending && value <= previous { break }
				unsafe { output[position] = previous }
				position--
			}
			unsafe { output[position] = value }
		}
		return length
	}

	mut children := [max_parts][max_values]i64{}
	mut lengths := [max_parts]int{}
	mut positions := [max_parts]int{}
	quotient := run_count / merge_inputs
	remainder := run_count % merge_inputs
	mut next_run := first_run
	mut total := 0
	for lane in 0 .. merge_inputs {
		mut child_count := quotient
		if lane < remainder { child_count++ }
		if child_count == 0 { continue }
		lengths[lane] = build_run(values, value_count, run_size, merge_inputs,
			next_run, child_count, !ascending, mut children[lane][0])
		next_run += child_count
		total += lengths[lane]
	}
	for out_index in 0 .. total {
		mut best_lane := max_parts
		mut best_value := i64(0)
		for lane in 0 .. merge_inputs {
			if positions[lane] >= lengths[lane] { continue }
			candidate := children[lane][lengths[lane] - 1 - positions[lane]]
			if best_lane == max_parts || (ascending && candidate < best_value) ||
				(!ascending && candidate > best_value) {
				best_lane = lane
				best_value = candidate
			}
		}
		unsafe { output[out_index] = best_value }
		positions[best_lane]++
	}
	return total
}

@[export: 'oscillating_merge_sort']
pub fn oscillating_merge_sort(mut values &i64, length usize) {
	if length == 0 || length > usize(max_values) || unsafe { values == nil } { return }
	count := int(length)
	mut sorted := [max_values]i64{}
	run_count := (count + initial_run_size - 1) / initial_run_size
	_ = build_run(values, count, initial_run_size, max_parts, 0,
		run_count, true, mut sorted[0])
	for i in 0 .. count { unsafe { values[i] = sorted[i] } }
}
