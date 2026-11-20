package morris_approximate_counter_base_three

import "core:c"

MAX_UPDATES :: 30
MAX_VALID_INPUT_VALUES :: 1 + MAX_UPDATES
MAX_PARSEABLE_INPUT_VALUES :: MAX_VALID_INPUT_VALUES + 1
DRAW_SPACE :: u64(205891132094649)

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
morris_approximate_counter_base_three :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_VALUES) do return -1
	updates_value := input[0]
	if updates_value < 0 || updates_value > MAX_UPDATES do return -1
	updates := int(updates_value)
	if length != c.size_t(1 + updates) do return -1

	state := 0
	threshold := DRAW_SPACE
	estimate := u64(0)
	for event := 0; event < updates; event += 1 {
		draw_value := input[1 + event]
		if draw_value < 0 || u64(draw_value) >= DRAW_SPACE do return -1
		if u64(draw_value) < threshold {
			state += 1
			threshold /= 3
			estimate = 3 * estimate + 1
		}
	}

	if output == nil || capacity < 16 do return -2
	store_i64_le(output, 0, i64(state))
	store_i64_le(output, 8, i64(estimate))
	return 16
}
