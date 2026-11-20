module morris_approximate_counter_base_three

import "core:c"

const max_updates = 30
const max_valid_input_values = 1 + max_updates
const max_parseable_input_values = max_valid_input_values + 1
const draw_space = u64(205891132094649)

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'morris_approximate_counter_base_three']
pub fn morris_approximate_counter_base_three(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_input_values { return -1 }
	updates_value := unsafe { input[0] }
	if updates_value < 0 || updates_value > max_updates { return -1 }
	updates := int(updates_value)
	if length != usize(1 + updates) { return -1 }

	mut state := 0
	mut threshold := draw_space
	mut estimate := u64(0)
	for event in 0 .. updates {
		draw_value := unsafe { input[1 + event] }
		if draw_value < 0 || u64(draw_value) >= draw_space { return -1 }
		if u64(draw_value) < threshold {
			state++
			threshold /= 3
			estimate = 3 * estimate + 1
		}
	}

	if unsafe { output == nil } || capacity < 16 { return -2 }
	store_i64_le(mut output, 0, i64(state))
	store_i64_le(mut output, 8, i64(estimate))
	return 16
}
