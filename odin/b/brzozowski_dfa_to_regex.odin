package brzozowski_dfa_to_regex

import "core:c"

MAX_STATES :: 3
MAX_TEXT :: 512
Text :: [MAX_TEXT]u8

text_len :: proc(text: []u8) -> int {
	length := 0
	for length < MAX_TEXT && text[length] != 0 { length += 1 }
	return length
}

copy_text :: proc(output: []u8, source: []u8) -> bool {
	length := text_len(source)
	if length >= MAX_TEXT do return false
	for index := 0; index <= length; index += 1 { output[index] = source[index] }
	return true
}

is_symbol :: proc(text: []u8, symbol: u8) -> bool {
	return text[0] == symbol && text[1] == 0
}

compare_text :: proc(left: []u8, right: []u8) -> int {
	left_len := text_len(left)
	right_len := text_len(right)
	shared := min(left_len, right_len)
	for index := 0; index < shared; index += 1 {
		if left[index] < right[index] do return -1
		if left[index] > right[index] do return 1
	}
	if left_len < right_len do return -1
	if left_len > right_len do return 1
	return 0
}

regex_union :: proc(output: []u8, left: []u8, right: []u8) -> bool {
	if is_symbol(left, '#') do return copy_text(output, right)
	if is_symbol(right, '#') || compare_text(left, right) == 0 do return copy_text(output, left)
	first := left
	second := right
	if compare_text(left, right) > 0 { first = right; second = left }
	var temporary: Text
	position := 0
	temporary[position] = '('; position += 1
	for index := 0; index < text_len(first); index += 1 { temporary[position] = first[index]; position += 1 }
	temporary[position] = '|'; position += 1
	for index := 0; index < text_len(second); index += 1 { temporary[position] = second[index]; position += 1 }
	temporary[position] = ')'
	return copy_text(output, temporary[:])
}

regex_concat :: proc(output: []u8, left: []u8, right: []u8) -> bool {
	if is_symbol(left, '#') || is_symbol(right, '#') {
		var empty: Text
		empty[0] = '#'
		return copy_text(output, empty[:])
	}
	if is_symbol(left, '@') do return copy_text(output, right)
	if is_symbol(right, '@') do return copy_text(output, left)
	var temporary: Text
	position := 0
	temporary[position] = '('; position += 1
	for index := 0; index < text_len(left); index += 1 { temporary[position] = left[index]; position += 1 }
	temporary[position] = '.'; position += 1
	for index := 0; index < text_len(right); index += 1 { temporary[position] = right[index]; position += 1 }
	temporary[position] = ')'
	return copy_text(output, temporary[:])
}

regex_star :: proc(output: []u8, value: []u8) -> bool {
	if is_symbol(value, '#') || is_symbol(value, '@') {
		var epsilon: Text
		epsilon[0] = '@'
		return copy_text(output, epsilon[:])
	}
	var temporary: Text
	position := 0
	temporary[position] = '('; position += 1
	for index := 0; index < text_len(value); index += 1 { temporary[position] = value[index]; position += 1 }
	temporary[position] = ')'; position += 1
	temporary[position] = '*'
	return copy_text(output, temporary[:])
}

@(export, link_name="brzozowski_dfa_to_regex")
brzozowski_dfa_to_regex :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 10 do return -1
	n64 := input[0]
	start64 := input[1]
	accepting := input[2]
	if n64 < 1 || n64 > MAX_STATES || start64 < 0 || start64 >= n64 ||
		accepting < 0 || accepting >= (i64(1) << n64) || length != c.size_t(3 + 2 * n64) do return -1
	n := int(n64)
	start := int(start64)
	var coefficient: [MAX_STATES][MAX_STATES]Text
	var constant: [MAX_STATES]Text
	for state := 0; state < n; state += 1 {
		constant[state][0] = if accepting & (i64(1) << state) != 0 { '@' } else { '#' }
		for target := 0; target < n; target += 1 { coefficient[state][target][0] = '#' }
		for symbol := 0; symbol < 2; symbol += 1 {
			next64 := input[3 + 2 * state + symbol]
			if next64 < 0 || next64 >= n64 do return -1
			next := int(next64)
			var label: Text
			label[0] = u8('0' + symbol)
			if !regex_union(coefficient[state][next][:], coefficient[state][next][:], label[:]) do return -1
		}
	}
	for pivot := 0; pivot < n; pivot += 1 {
		if pivot == start do continue
		var loop: Text
		if !regex_star(loop[:], coefficient[pivot][pivot][:]) do return -1
		for source := 0; source < n; source += 1 {
			if source == pivot do continue
			var prefix: Text
			if !regex_concat(prefix[:], coefficient[source][pivot][:], loop[:]) do return -1
			for target := 0; target < n; target += 1 {
				if target == pivot do continue
				var through: Text
				if !regex_concat(through[:], prefix[:], coefficient[pivot][target][:]) ||
					!regex_union(coefficient[source][target][:], coefficient[source][target][:], through[:]) do return -1
			}
			var through_constant: Text
			if !regex_concat(through_constant[:], prefix[:], constant[pivot][:]) ||
				!regex_union(constant[source][:], constant[source][:], through_constant[:]) do return -1
		}
	}
	var loop: Text
	var answer: Text
	if !regex_star(loop[:], coefficient[start][start][:]) || !regex_concat(answer[:], loop[:], constant[start][:]) do return -1
	result_length := text_len(answer[:])
	if result_length > 270 do return -1
	if output == nil || output_capacity < c.size_t(result_length) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = answer[index] }
	return i64(result_length)
}
