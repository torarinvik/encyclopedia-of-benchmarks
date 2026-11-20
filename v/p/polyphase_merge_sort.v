module polyphase_merge_sort

const max_items = 256
const run_size = 8
const max_runs = 34

fn place_run(input &i64, input_length int, run_index u32, tape int,
	mut tapes [3][max_items]i64, mut starts [3][max_runs]u32,
	mut lengths [3][max_runs]u32, mut counts [3]u32, mut write_offsets [3]u32) {
	slot := int(counts[tape])
	counts[tape]++
	start := int(write_offsets[tape])
	source := int(run_index) * run_size
	run_length := min(input_length - source, run_size)
	unsafe {
		for i in 0 .. run_length { tapes[tape][start + i] = input[source + i] }
	}
	for i in 1 .. run_length {
		value := tapes[tape][start + i]
		mut position := i
		for position > 0 && tapes[tape][start + position - 1] > value {
			tapes[tape][start + position] = tapes[tape][start + position - 1]
			position--
		}
		tapes[tape][start + position] = value
	}
	starts[tape][slot] = u32(start)
	lengths[tape][slot] = u32(run_length)
	write_offsets[tape] += u32(run_length)
}

fn place_dummy(tape int, mut starts [3][max_runs]u32, mut lengths [3][max_runs]u32,
	mut counts [3]u32, write_offsets [3]u32) {
	slot := int(counts[tape])
	counts[tape]++
	starts[tape][slot] = write_offsets[tape]
	lengths[tape][slot] = 0
}

fn merge_run(mut tapes [3][max_items]i64, mut starts [3][max_runs]u32,
	mut lengths [3][max_runs]u32, mut counts [3]u32, mut read_indices [3]u32,
	mut write_offsets [3]u32, left_tape int, right_tape int, output_tape int) {
	left_slot := int(read_indices[left_tape])
	right_slot := int(read_indices[right_tape])
	read_indices[left_tape]++
	read_indices[right_tape]++
	left_start := int(starts[left_tape][left_slot])
	right_start := int(starts[right_tape][right_slot])
	left_length := int(lengths[left_tape][left_slot])
	right_length := int(lengths[right_tape][right_slot])
	output_slot := int(counts[output_tape])
	counts[output_tape]++
	output_start := int(write_offsets[output_tape])
	mut left := 0
	mut right := 0
	mut written := 0
	for left < left_length && right < right_length {
		if tapes[left_tape][left_start + left] <= tapes[right_tape][right_start + right] {
			tapes[output_tape][output_start + written] = tapes[left_tape][left_start + left]
			left++
		} else {
			tapes[output_tape][output_start + written] = tapes[right_tape][right_start + right]
			right++
		}
		written++
	}
	for left < left_length { tapes[output_tape][output_start + written] = tapes[left_tape][left_start + left]; left++; written++ }
	for right < right_length { tapes[output_tape][output_start + written] = tapes[right_tape][right_start + right]; right++; written++ }
	starts[output_tape][output_slot] = u32(output_start)
	lengths[output_tape][output_slot] = u32(written)
	write_offsets[output_tape] += u32(written)
}

@[export: 'polyphase_merge_sort']
pub fn polyphase_merge_sort(values &i64, length usize) {
	unsafe {
		if values == nil || length < 2 || length > max_items { return }
		mut tapes := [3][max_items]i64{}
		mut starts := [3][max_runs]u32{}
		mut run_lengths := [3][max_runs]u32{}
		mut counts := [3]u32{}
		mut read_indices := [3]u32{}
		mut write_offsets := [3]u32{}
		initial_runs := u32((int(length) + run_size - 1) / run_size)
		mut quota_a := u32(1)
		mut quota_b := u32(0)
		for quota_a + quota_b < initial_runs {
			next := quota_a + quota_b
			quota_b = quota_a
			quota_a = next
		}
		mut run := u32(0)
		for slot := u32(0); slot < quota_a; slot++ {
			if run < initial_runs { place_run(values, int(length), run, 0, mut tapes, mut starts, mut run_lengths, mut counts, mut write_offsets) }
			else { place_dummy(0, mut starts, mut run_lengths, mut counts, write_offsets) }
			run++
		}
		for slot := u32(0); slot < quota_b; slot++ {
			if run < initial_runs { place_run(values, int(length), run, 1, mut tapes, mut starts, mut run_lengths, mut counts, mut write_offsets) }
			else { place_dummy(1, mut starts, mut run_lengths, mut counts, write_offsets) }
			run++
		}
		mut roles := [3]u32{}
		roles[1] = 1
		roles[2] = 2
		mut remaining_total := counts[0] + counts[1]
		for remaining_total > 1 {
			input_a, input_b, output := int(roles[0]), int(roles[1]), int(roles[2])
			available_a := counts[input_a] - read_indices[input_a]
			available_b := counts[input_b] - read_indices[input_b]
			if available_a == 0 || available_b == 0 { break }
			counts[output], read_indices[output], write_offsets[output] = 0, 0, 0
			pairs := min(available_a, available_b)
			for _ in 0 .. pairs { merge_run(mut tapes, mut starts, mut run_lengths, mut counts, mut read_indices, mut write_offsets, input_a, input_b, output) }
			left_a := counts[input_a] - read_indices[input_a]
			left_b := counts[input_b] - read_indices[input_b]
			remaining_total = left_a + left_b + counts[output]
			if remaining_total <= 1 || (left_a == 0 && left_b == 0) { break }
			if left_a > 0 { roles[1] = roles[2]; roles[2] = u32(input_b) }
			else { roles[0] = roles[2]; roles[2] = u32(input_a) }
		}
		for tape in 0 .. 3 {
			if read_indices[tape] < counts[tape] {
				slot := int(read_indices[tape])
				if int(run_lengths[tape][slot]) == int(length) {
					start := int(starts[tape][slot])
					for i in 0 .. int(length) { values[i] = tapes[tape][start + i] }
					return
				}
			}
		}
	}
}
