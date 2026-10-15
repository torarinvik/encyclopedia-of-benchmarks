package count_and_say

import "core:c"

MAX_TERM_LENGTH :: 256

@(export)
count_and_say :: proc "contextless" (term_index: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if term_index < 1 || term_index > 19 do return -1
	current: [MAX_TERM_LENGTH]u8
	next: [MAX_TERM_LENGTH]u8
	current_length := c.size_t(1)
	current[0] = u8('1')
	for term := i64(1); term < term_index; term += 1 {
		next_length := c.size_t(0)
		index := c.size_t(0)
		for index < current_length {
			ending := index + 1
			for ending < current_length && current[ending] == current[index] {
				ending += 1
			}
			run_length := ending - index
			if next_length + 2 > MAX_TERM_LENGTH do return -1
			next[next_length] = u8('0') + u8(run_length)
			next[next_length + 1] = current[index]
			next_length += 2
			index = ending
		}
		for position := c.size_t(0); position < next_length; position += 1 {
			current[position] = next[position]
		}
		current_length = next_length
	}
	if output_capacity < current_length || output == nil do return -2
	for index := c.size_t(0); index < current_length; index += 1 { output[index] = current[index] }
	return i64(current_length)
}
