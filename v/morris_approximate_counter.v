module morris_approximate_counter

const max_updates = 53
const draw_bits = 53
const max_input_values = 1 + max_updates
const draw_limit = u64(1) << u64(draw_bits)

fn store_i64_le(mut output &u8, offset usize, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'morris_approximate_counter']
pub fn morris_approximate_counter(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	updates_value := unsafe { input[0] }
	if updates_value < 1 || updates_value > max_updates { return -1 }
	updates := int(updates_value)
	if length != usize(1 + updates) { return -1 }

	mut state := 0
	for event in 0 .. updates {
		draw_value := unsafe { input[1 + event] }
		if draw_value < 0 || u64(draw_value) >= draw_limit { return -1 }
		threshold := u64(1) << u64(draw_bits - state)
		if u64(draw_value) < threshold { state++ }
	}

	if unsafe { output == nil } || capacity < 16 { return -2 }
	estimate := i64((u64(1) << u64(state)) - 1)
	store_i64_le(mut output, 0, i64(state))
	store_i64_le(mut output, 8, estimate)
	return 16
}
