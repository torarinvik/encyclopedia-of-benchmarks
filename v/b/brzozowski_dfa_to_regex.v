module brzozowski_dfa_to_regex

const max_states = 3
const max_text = 512

fn text_len(text []u8) int {
	mut length := 0
	for length < max_text && text[length] != 0 { length++ }
	return length
}

fn copy_text(mut output []u8, source []u8) bool {
	length := text_len(source)
	if length >= max_text { return false }
	for index in 0 .. length + 1 { output[index] = source[index] }
	return true
}

fn is_symbol(text []u8, symbol u8) bool {
	return text[0] == symbol && text[1] == 0
}

fn compare_text(left []u8, right []u8) int {
	left_len := text_len(left)
	right_len := text_len(right)
	shared := if left_len < right_len { left_len } else { right_len }
	for index in 0 .. shared {
		if left[index] < right[index] { return -1 }
		if left[index] > right[index] { return 1 }
	}
	if left_len < right_len { return -1 }
	if left_len > right_len { return 1 }
	return 0
}

fn regex_union(mut output []u8, left []u8, right []u8) bool {
	if is_symbol(left, `#`) { return copy_text(mut output, right) }
	if is_symbol(right, `#`) || compare_text(left, right) == 0 { return copy_text(mut output, left) }
	first := if compare_text(left, right) < 0 { left } else { right }
	second := if compare_text(left, right) < 0 { right } else { left }
	mut temporary := [max_text]u8{}
	mut position := 0
	temporary[position] = `(`; position++
	for index in 0 .. text_len(first) { temporary[position] = first[index]; position++ }
	temporary[position] = `|`; position++
	for index in 0 .. text_len(second) { temporary[position] = second[index]; position++ }
	temporary[position] = `)`
	return copy_text(mut output, temporary[..])
}

fn regex_concat(mut output []u8, left []u8, right []u8) bool {
	if is_symbol(left, `#`) || is_symbol(right, `#`) {
		mut empty := [max_text]u8{}
		empty[0] = `#`
		return copy_text(mut output, empty[..])
	}
	if is_symbol(left, `@`) { return copy_text(mut output, right) }
	if is_symbol(right, `@`) { return copy_text(mut output, left) }
	mut temporary := [max_text]u8{}
	mut position := 0
	temporary[position] = `(`; position++
	for index in 0 .. text_len(left) { temporary[position] = left[index]; position++ }
	temporary[position] = `.`; position++
	for index in 0 .. text_len(right) { temporary[position] = right[index]; position++ }
	temporary[position] = `)`
	return copy_text(mut output, temporary[..])
}

fn regex_star(mut output []u8, value []u8) bool {
	if is_symbol(value, `#`) || is_symbol(value, `@`) {
		mut epsilon := [max_text]u8{}
		epsilon[0] = `@`
		return copy_text(mut output, epsilon[..])
	}
	mut temporary := [max_text]u8{}
	mut position := 0
	temporary[position] = `(`; position++
	for index in 0 .. text_len(value) { temporary[position] = value[index]; position++ }
	temporary[position] = `)`; position++
	temporary[position] = `*`
	return copy_text(mut output, temporary[..])
}

@[export: 'brzozowski_dfa_to_regex']
pub fn brzozowski_dfa_to_regex(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 10 { return -1 }
		n_value := input[0]
		start_value := input[1]
		accepting := input[2]
		if n_value < 1 || n_value > max_states || start_value < 0 || start_value >= n_value ||
			accepting < 0 || accepting >= (i64(1) << int(n_value)) || length != usize(3 + 2 * n_value) { return -1 }
		n := int(n_value)
		start := int(start_value)
		mut coefficient := [max_states * max_states * max_text]u8{}
		mut constant := [max_states * max_text]u8{}
		for state in 0 .. n {
			constant_offset := state * max_text
			constant[constant_offset] = if accepting & (i64(1) << state) != 0 { `@` } else { `#` }
			for target in 0 .. n {
				offset := (state * max_states + target) * max_text
				coefficient[offset] = `#`
			}
			for symbol in 0 .. 2 {
				next_value := input[3 + 2 * state + symbol]
				if next_value < 0 || next_value >= n_value { return -1 }
				next := int(next_value)
				var label := [max_text]u8{}
				label[0] = u8(`0` + symbol)
				offset := (state * max_states + next) * max_text
				if !regex_union(mut coefficient[offset..offset + max_text], coefficient[offset..offset + max_text], label[..]) { return -1 }
			}
		}
		for pivot in 0 .. n {
			if pivot == start { continue }
			var loop := [max_text]u8{}
			pivot_diag := (pivot * max_states + pivot) * max_text
			if !regex_star(mut loop[..], coefficient[pivot_diag..pivot_diag + max_text]) { return -1 }
			for source in 0 .. n {
				if source == pivot { continue }
				var prefix := [max_text]u8{}
				column_offset := (source * max_states + pivot) * max_text
				if !regex_concat(mut prefix[..], coefficient[column_offset..column_offset + max_text], loop[..]) { return -1 }
				for target in 0 .. n {
					if target == pivot { continue }
					var through := [max_text]u8{}
					row_offset := (pivot * max_states + target) * max_text
					if !regex_concat(mut through[..], prefix[..], coefficient[row_offset..row_offset + max_text]) { return -1 }
					target_offset := (source * max_states + target) * max_text
					if !regex_union(mut coefficient[target_offset..target_offset + max_text], coefficient[target_offset..target_offset + max_text], through[..]) { return -1 }
				}
				var through_constant := [max_text]u8{}
				constant_offset := pivot * max_text
				if !regex_concat(mut through_constant[..], prefix[..], constant[constant_offset..constant_offset + max_text]) { return -1 }
				constant_source := source * max_text
				if !regex_union(mut constant[constant_source..constant_source + max_text], constant[constant_source..constant_source + max_text], through_constant[..]) { return -1 }
			}
		}
		var loop := [max_text]u8{}
		var answer := [max_text]u8{}
		start_diag := (start * max_states + start) * max_text
		start_constant := start * max_text
		if !regex_star(mut loop[..], coefficient[start_diag..start_diag + max_text]) ||
			!regex_concat(mut answer[..], loop[..], constant[start_constant..start_constant + max_text]) { return -1 }
		result_length := text_len(answer[..])
		if result_length > 270 { return -1 }
		if output == nil || output_capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length { output[index] = answer[index] }
		return i64(result_length)
	}
}
