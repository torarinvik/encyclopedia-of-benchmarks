package subtractive_prng_bentley_seeded_sequence

import "core:c"

STATE_SIZE :: 55
SHORT_LAG :: 24
WARMUP_VALUES :: 165
MODULUS :: i32(1_000_000_000)

put_i64_le :: proc(output: [^]u8, offset: usize, value: i32) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + usize(byte)] = u8(bits >> u64(8 * byte))
	}
}

@(export)
subtractive_prng_bentley_seeded_sequence :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length != 2 do return -1
	seed, count := input[0], input[1]
	if seed < 0 || seed >= 1_000_000_000 || count < 0 || count > 64 do return -1
	n := int(count)
	required := n * 8
	if int(capacity) < required || (required > 0 && output == nil) do return -2
	if n == 0 do return 0

	seed_state: [STATE_SIZE]i32
	ring: [STATE_SIZE]i32
	seed_state[0] = i32(seed)
	seed_state[1] = 1
	for i: usize = 2; i < STATE_SIZE; i += 1 {
		value := seed_state[i - 2] - seed_state[i - 1]
		if value < 0 do value += MODULUS
		seed_state[i] = value
	}
	for i: usize = 0; i < STATE_SIZE; i += 1 {
		ring[i] = seed_state[(34 * (i + 1)) % STATE_SIZE]
	}

	write_index: usize = 0
	lag_index: usize = STATE_SIZE - SHORT_LAG
	for step: usize = 0; step < WARMUP_VALUES + usize(n); step += 1 {
		value := ring[write_index] - ring[lag_index]
		if value < 0 do value += MODULUS
		ring[write_index] = value
		if step >= WARMUP_VALUES {
			put_i64_le(output, (step - WARMUP_VALUES) * 8, value)
		}
		write_index = (write_index + 1) % STATE_SIZE
		lag_index = (lag_index + 1) % STATE_SIZE
	}
	return i64(required)
}
