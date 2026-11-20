package digital_filter_direct_form_ii_transposed

import "core:c"

MAX_SAMPLES :: 32
MAX_ORDER :: 4
MAX_INPUT_WORDS :: 45

@(export)
digital_filter_direct_form_ii_transposed :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_WORDS do return -1
	count_word := input[0]
	order_word := input[1]
	if count_word < 0 || count_word > MAX_SAMPLES || order_word < 0 || order_word > MAX_ORDER do return -1
	count := int(count_word)
	order := int(order_word)
	if length != c.size_t(count + 2 * order + 4) do return -1
	a_start := 2
	b_start := order + 3
	x_start := 2 * order + 4
	if input[a_start] != 1 do return -1
	for index := 1; index <= order; index += 1 do if input[a_start + index] < -1 || input[a_start + index] > 1 do return -1
	for index := 0; index <= order; index += 1 do if input[b_start + index] < -1 || input[b_start + index] > 1 do return -1
	for index := 0; index < count; index += 1 do if input[x_start + index] < -16 || input[x_start + index] > 16 do return -1
	bytes := count * 8
	if bytes > 0 && (output == nil || capacity < c.size_t(bytes)) do return -2
	if count == 0 do return 0
	state: [4]i64 = [4]i64{}
	for sample_index := 0; sample_index < count; sample_index += 1 {
		sample := input[x_start + sample_index]
		value := input[b_start] * sample
		if order > 0 do value += state[0]
		for stage := 0; stage < order; stage += 1 {
			next_state := i64(0)
			if stage + 1 < order do next_state = state[stage + 1]
			state[stage] = next_state + input[b_start + stage + 1] * sample - input[a_start + stage + 1] * value
		}
		bits := u64(value)
		for byte := 0; byte < 8; byte += 1 do output[sample_index * 8 + byte] = u8((bits >> (8 * byte)) & 255)
	}
	return i64(bytes)
}
