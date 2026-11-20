package polyphase_merge_sort

import "core:c"

MAX_ITEMS :: 256
RUN_SIZE :: 8
MAX_RUNS :: 34
Tapes :: [3][MAX_ITEMS]i64
Run_Table :: [3][MAX_RUNS]u32
Tape_Counts :: [3]u32

place_run :: proc(input: [^]i64, input_length: int, run_index: u32, tape: int,
		tapes: ^Tapes, starts, lengths: ^Run_Table, counts, write_offsets: ^Tape_Counts) {
	slot := int(counts[tape])
	counts[tape] += 1
	start := int(write_offsets[tape])
	source := int(run_index)*RUN_SIZE
	run_length := min(input_length-source, RUN_SIZE)
	for i := 0; i < run_length; i += 1 { tapes[tape][start+i] = input[source+i] }
	for i := 1; i < run_length; i += 1 {
		value := tapes[tape][start+i]
		position := i
		for position > 0 && tapes[tape][start+position-1] > value {
			tapes[tape][start+position] = tapes[tape][start+position-1]
			position -= 1
		}
		tapes[tape][start+position] = value
	}
	starts[tape][slot] = u32(start)
	lengths[tape][slot] = u32(run_length)
	write_offsets[tape] += u32(run_length)
}

place_dummy :: proc(tape: int, starts, lengths: ^Run_Table, counts: ^Tape_Counts,
		write_offsets: ^Tape_Counts) {
	slot := int(counts[tape])
	counts[tape] += 1
	starts[tape][slot] = write_offsets[tape]
	lengths[tape][slot] = 0
}

merge_run :: proc(tapes: ^Tapes, starts, lengths: ^Run_Table,
		counts, read_indices, write_offsets: ^Tape_Counts,
		left_tape, right_tape, output_tape: int) {
	left_slot, right_slot := int(read_indices[left_tape]), int(read_indices[right_tape])
	read_indices[left_tape] += 1
	read_indices[right_tape] += 1
	left_start, right_start := int(starts[left_tape][left_slot]), int(starts[right_tape][right_slot])
	left_length, right_length := int(lengths[left_tape][left_slot]), int(lengths[right_tape][right_slot])
	output_slot := int(counts[output_tape])
	counts[output_tape] += 1
	output_start := int(write_offsets[output_tape])
	left, right, written := 0, 0, 0
	for left < left_length && right < right_length {
		if tapes[left_tape][left_start+left] <= tapes[right_tape][right_start+right] {
			tapes[output_tape][output_start+written] = tapes[left_tape][left_start+left]
			left += 1
		} else {
			tapes[output_tape][output_start+written] = tapes[right_tape][right_start+right]
			right += 1
		}
		written += 1
	}
	for left < left_length { tapes[output_tape][output_start+written] = tapes[left_tape][left_start+left]; left += 1; written += 1 }
	for right < right_length { tapes[output_tape][output_start+written] = tapes[right_tape][right_start+right]; right += 1; written += 1 }
	starts[output_tape][output_slot] = u32(output_start)
	lengths[output_tape][output_slot] = u32(written)
	write_offsets[output_tape] += u32(written)
}

@(export)
polyphase_merge_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if values == nil || length < 2 || length > MAX_ITEMS do return
	n := int(length)
	var tapes: Tapes
	var starts, run_lengths: Run_Table
	var counts, read_indices, write_offsets: Tape_Counts
	initial_runs := u32((n+RUN_SIZE-1)/RUN_SIZE)
	quota_a, quota_b := u32(1), u32(0)
	for quota_a+quota_b < initial_runs {
		next := quota_a+quota_b
		quota_b = quota_a
		quota_a = next
	}
	run := u32(0)
	for slot := u32(0); slot < quota_a; slot += 1 {
		if run < initial_runs { place_run(values,n,run,0,&tapes,&starts,&run_lengths,&counts,&write_offsets) }
		else { place_dummy(0,&starts,&run_lengths,&counts,&write_offsets) }
		run += 1
	}
	for slot := u32(0); slot < quota_b; slot += 1 {
		if run < initial_runs { place_run(values,n,run,1,&tapes,&starts,&run_lengths,&counts,&write_offsets) }
		else { place_dummy(1,&starts,&run_lengths,&counts,&write_offsets) }
		run += 1
	}
	input_a, input_b, output := u32(0), u32(1), u32(2)
	remaining_total := counts[0]+counts[1]
	for remaining_total > 1 {
		a, b, out := int(input_a), int(input_b), int(output)
		available_a := counts[a]-read_indices[a]
		available_b := counts[b]-read_indices[b]
		if available_a == 0 || available_b == 0 do break
		counts[out], read_indices[out], write_offsets[out] = 0, 0, 0
		pairs := min(available_a,available_b)
		for pair := u32(0); pair < pairs; pair += 1 { merge_run(&tapes,&starts,&run_lengths,&counts,&read_indices,&write_offsets,a,b,out) }
		left_a, left_b := counts[a]-read_indices[a], counts[b]-read_indices[b]
		remaining_total = left_a+left_b+counts[out]
		if remaining_total <= 1 || (left_a == 0 && left_b == 0) do break
		if left_a > 0 { input_b, output = output, input_b }
		else { input_a, output = output, input_a }
	}
	for tape := 0; tape < 3; tape += 1 {
		if read_indices[tape] < counts[tape] {
			slot := int(read_indices[tape])
			if int(run_lengths[tape][slot]) == n {
				start := int(starts[tape][slot])
				for i := 0; i < n; i += 1 { values[i] = tapes[tape][start+i] }
				return
			}
		}
	}
}
