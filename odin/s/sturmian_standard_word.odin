package sturmian_standard_word

import "core:c"

MAX_STEPS :: 4
MAX_WORD :: 41

@(export)
sturmian_standard_word :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 6 do return -1
	steps_word := values[0]
	if steps_word < 0 || steps_word > MAX_STEPS do return -1
	steps := int(steps_word)
	if length != c.size_t(steps + 1) do return -1

	directives: [MAX_STEPS]i64
	for i in 0..<steps {
		repeat := values[i + 1]
		if i == 0 {
			if repeat < 0 || repeat > 2 do return -1
		} else {
			if repeat < 1 || repeat > 2 do return -1
		}
		directives[i] = repeat
	}

	previous: [MAX_WORD]u8
	current: [MAX_WORD]u8
	following: [MAX_WORD]u8
	previous[0] = 'b'
	current[0] = 'a'
	previous_length := 1
	current_length := 1
	for step in 0..<steps {
		repeat := int(directives[step])
		following_length := current_length * repeat + previous_length
		position := 0
		for _ in 0..<repeat {
			for i in 0..<current_length {
				following[position] = current[i]
				position += 1
			}
		}
		for i in 0..<previous_length {
			following[position] = previous[i]
			position += 1
		}
		for i in 0..<current_length { previous[i] = current[i] }
		for i in 0..<following_length { current[i] = following[i] }
		previous_length = current_length
		current_length = following_length
	}

	if output == nil || capacity < c.size_t(current_length) do return -2
	for i in 0..<current_length { output[i] = current[i] }
	return i64(current_length)
}
