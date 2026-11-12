module create_maximum_number

const max_source_length = 6
const max_input_length = 16
const max_output_length = 12

struct Sequence {
mut:
	values [max_output_length]u8
	length int
}

fn maximum_subsequence(input &i64, base int, length int, requested int) Sequence {
	mut stack := [max_source_length]u8{}
	mut stack_length := 0
	mut deletions := length - requested
	for i in 0 .. length {
		digit := unsafe { u8(input[base + i]) }
		for deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit {
			stack_length--
			deletions--
		}
		stack[stack_length] = digit
		stack_length++
	}
	stack_length -= deletions
	mut selected := Sequence{}
	selected.length = stack_length
	for i in 0 .. stack_length { selected.values[i] = stack[i] }
	return selected
}

fn compare_suffix(first Sequence, first_at int, second Sequence, second_at int) int {
	mut i := first_at
	mut j := second_at
	for i < first.length && j < second.length {
		if first.values[i] != second.values[j] {
			return if first.values[i] > second.values[j] { 1 } else { -1 }
		}
		i++
		j++
	}
	if i == first.length && j == second.length { return 0 }
	return if i == first.length { -1 } else { 1 }
}

fn merge_sequences(first Sequence, second Sequence) Sequence {
	mut merged := Sequence{}
	mut i := 0
	mut j := 0
	for i < first.length || j < second.length {
		order := compare_suffix(first, i, second, j)
		if j == second.length || (i < first.length && order >= 0) {
			merged.values[merged.length] = first.values[i]
			i++
		} else {
			merged.values[merged.length] = second.values[j]
			j++
		}
		merged.length++
	}
	return merged
}

fn greater(left Sequence, right Sequence) bool {
	for i in 0 .. left.length {
		if left.values[i] != right.values[i] { return left.values[i] > right.values[i] }
	}
	return false
}

@[export: 'create_maximum_number']
pub fn create_maximum_number(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_source_length || input[1] < 0 || input[1] > max_source_length { return -1 }
		first_length := int(input[0])
		second_length := int(input[1])
		if input[2] < 0 || input[2] > first_length + second_length { return -1 }
		requested := int(input[2])
		if length != usize(3 + first_length + second_length) { return -1 }
		for i in 0 .. first_length + second_length {
			if input[3 + i] < 0 || input[3 + i] > 9 { return -1 }
		}
		if output == nil || capacity < usize(requested) { return -2 }

		minimum_first := max(0, requested - second_length)
		maximum_first := min(requested, first_length)
		mut best := Sequence{}
		mut have_best := false
		for take_first := minimum_first; take_first <= maximum_first; take_first++ {
			first := maximum_subsequence(input, 3, first_length, take_first)
			second := maximum_subsequence(input, 3 + first_length, second_length, requested - take_first)
			candidate := merge_sequences(first, second)
			if !have_best || greater(candidate, best) {
				best = candidate
				have_best = true
			}
		}
		for i in 0 .. requested { output[i] = best.values[i] }
		return i64(requested)
	}
}
