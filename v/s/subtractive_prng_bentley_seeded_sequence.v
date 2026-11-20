module subtractive_prng_bentley_seeded_sequence

const state_size = 55
const short_lag = 24
const warmup_values = 165
const modulus = i32(1_000_000_000)

fn put_i64_le(mut output &u8, offset int, value i32) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'subtractive_prng_bentley_seeded_sequence']
pub fn subtractive_prng_bentley_seeded_sequence(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	seed := unsafe { input[0] }
	count := unsafe { input[1] }
	if seed < 0 || seed >= 1_000_000_000 || count < 0 || count > 64 { return -1 }
	n := int(count)
	required := n * 8
	if capacity < usize(required) || (required > 0 && unsafe { output == nil }) { return -2 }
	if n == 0 { return 0 }

	mut seed_state := [state_size]i32{}
	mut ring := [state_size]i32{}
	seed_state[0] = i32(seed)
	seed_state[1] = 1
	for i in 2 .. state_size {
		mut value := seed_state[i - 2] - seed_state[i - 1]
		if value < 0 { value += modulus }
		seed_state[i] = value
	}
	for i in 0 .. state_size {
		ring[i] = seed_state[(34 * (i + 1)) % state_size]
	}

	mut write_index := 0
	mut lag_index := state_size - short_lag
	for step in 0 .. warmup_values + n {
		mut value := ring[write_index] - ring[lag_index]
		if value < 0 { value += modulus }
		ring[write_index] = value
		if step >= warmup_values {
			put_i64_le(mut output, (step - warmup_values) * 8, value)
		}
		write_index = (write_index + 1) % state_size
		lag_index = (lag_index + 1) % state_size
	}
	return i64(required)
}
