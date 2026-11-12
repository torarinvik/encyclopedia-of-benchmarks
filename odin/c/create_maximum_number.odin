package create_maximum_number

import "core:c"

MAX_SOURCE_LENGTH :: 6
MAX_INPUT_LENGTH :: 16
MAX_OUTPUT_LENGTH :: 12

Sequence :: struct {
	values: [MAX_OUTPUT_LENGTH]u8,
	length: int,
}

maximum_subsequence :: proc(input: [^]i64, base, length, requested: int) -> Sequence {
	stack: [MAX_SOURCE_LENGTH]u8
	stack_length := 0
	deletions := length - requested
	for i := 0; i < length; i += 1 {
		digit := u8(input[base + i])
		for deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit {
			stack_length -= 1
			deletions -= 1
		}
		stack[stack_length] = digit
		stack_length += 1
	}
	stack_length -= deletions
	selected: Sequence
	selected.length = stack_length
	for i := 0; i < stack_length; i += 1 { selected.values[i] = stack[i] }
	return selected
}

compare_suffix :: proc(first, second: ^Sequence, i0, j0: int) -> int {
	i, j := i0, j0
	for i < first.length && j < second.length {
		if first.values[i] != second.values[j] {
			return if first.values[i] > second.values[j] do 1 else -1
		}
		i += 1
		j += 1
	}
	if i == first.length && j == second.length do return 0
	return if i == first.length do -1 else 1
}

merge_sequences :: proc(first, second: ^Sequence) -> Sequence {
	merged: Sequence
	i, j := 0, 0
	for i < first.length || j < second.length {
		order := compare_suffix(first, second, i, j)
		if j == second.length || (i < first.length && order >= 0) {
			merged.values[merged.length] = first.values[i]
			i += 1
		} else {
			merged.values[merged.length] = second.values[j]
			j += 1
		}
		merged.length += 1
	}
	return merged
}

greater :: proc(left, right: ^Sequence) -> bool {
	for i := 0; i < left.length; i += 1 {
		if left.values[i] != right.values[i] do return left.values[i] > right.values[i]
	}
	return false
}

@(export, link_name="create_maximum_number")
create_maximum_number :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_SOURCE_LENGTH || input[1] < 0 || input[1] > MAX_SOURCE_LENGTH do return -1
	first_length := int(input[0])
	second_length := int(input[1])
	if input[2] < 0 || input[2] > first_length + second_length do return -1
	requested := int(input[2])
	if length != c.size_t(3 + first_length + second_length) do return -1
	for i := 0; i < first_length + second_length; i += 1 {
		if input[3 + i] < 0 || input[3 + i] > 9 do return -1
	}
	if output == nil || capacity < c.size_t(requested) do return -2

	minimum_first := max(0, requested - second_length)
	maximum_first := min(requested, first_length)
	best: Sequence
	have_best := false
	for take_first := minimum_first; take_first <= maximum_first; take_first += 1 {
		first := maximum_subsequence(input, 3, first_length, take_first)
		second := maximum_subsequence(input, 3 + first_length, second_length, requested - take_first)
		candidate := merge_sequences(&first, &second)
		if !have_best || greater(&candidate, &best) {
			best = candidate
			have_best = true
		}
	}
	for i := 0; i < requested; i += 1 { output[i] = best.values[i] }
	return i64(requested)
}
