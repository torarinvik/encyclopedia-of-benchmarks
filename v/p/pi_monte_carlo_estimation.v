module pi_monte_carlo_estimation

const mt_n = 624
const mt_m = 397
const mt_mask = u64(0xffffffff)
const max_parseable_input_length = 3

struct Mt19937 {
mut:
	state [mt_n]u32
	index int
}

fn mt_seed(seed u32) Mt19937 {
	mut rng := Mt19937{}
	rng.state[0] = 19650218
	for index in 1 .. mt_n {
		previous := u64(rng.state[index - 1])
		mixed := previous ^ (previous >> 30)
		rng.state[index] = u32((u64(1812433253) * mixed + u64(index)) & mt_mask)
	}
	mut index, mut key_index := 1, 0
	for _ in 0 .. mt_n {
		previous := u64(rng.state[index - 1])
		mixed := ((previous ^ (previous >> 30)) * 1664525) & mt_mask
		value := (u64(rng.state[index]) ^ mixed) + u64(seed) + u64(key_index)
		rng.state[index] = u32(value & mt_mask)
		index++
		key_index++
		if index >= mt_n { rng.state[0] = rng.state[mt_n - 1]; index = 1 }
		if key_index >= 1 { key_index = 0 }
	}
	for _ in 0 .. mt_n - 1 {
		previous := u64(rng.state[index - 1])
		mixed := ((previous ^ (previous >> 30)) * 1566083941) & mt_mask
		value := (u64(rng.state[index]) ^ mixed) - u64(index)
		rng.state[index] = u32(value & mt_mask)
		index++
		if index >= mt_n { rng.state[0] = rng.state[mt_n - 1]; index = 1 }
	}
	rng.state[0] = 0x80000000
	rng.index = mt_n
	return rng
}

fn mt_next_u32(mut rng Mt19937) u32 {
	if rng.index >= mt_n {
		for index in 0 .. mt_n - mt_m {
			joined := (rng.state[index] & 0x80000000) | (rng.state[index + 1] & 0x7fffffff)
			magic := u32(0)
			if joined & 1 != 0 { magic = 0x9908b0df }
			rng.state[index] = rng.state[index + mt_m] ^ (joined >> 1) ^ magic
		}
		for index in mt_n - mt_m .. mt_n - 1 {
			joined := (rng.state[index] & 0x80000000) | (rng.state[index + 1] & 0x7fffffff)
			magic := u32(0)
			if joined & 1 != 0 { magic = 0x9908b0df }
			rng.state[index] = rng.state[index - (mt_n - mt_m)] ^ (joined >> 1) ^ magic
		}
		joined := (rng.state[mt_n - 1] & 0x80000000) | (rng.state[0] & 0x7fffffff)
		magic := u32(0)
		if joined & 1 != 0 { magic = 0x9908b0df }
		rng.state[mt_n - 1] = rng.state[mt_m - 1] ^ (joined >> 1) ^ magic
		rng.index = 0
	}
	mut value := rng.state[rng.index]
	rng.index++
	value ^= value >> 11
	value ^= (value << 7) & 0x9d2c5680
	value ^= (value << 15) & 0xefc60000
	value ^= value >> 18
	return value
}

fn mt_random(mut rng Mt19937) f64 {
	high := mt_next_u32(mut rng) >> 5
	low := mt_next_u32(mut rng) >> 6
	return (f64(high) * 67108864.0 + f64(low)) * (1.0 / 9007199254740992.0)
}

@[export: 'pi_monte_carlo_estimation']
pub fn pi_monte_carlo_estimation(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 1 || input_length > usize(max_parseable_input_length) { return -1 }
	if input_length != 2 { return -1 }
	unsafe {
		simulations_value, seed_value := input[0], input[1]
		if simulations_value != simulations_value || seed_value != seed_value { return -1 }
		if simulations_value < 1.0 || simulations_value > 100000.0 || seed_value < 0.0 || seed_value > 4294967295.0 { return -1 }
		if simulations_value != f64(i64(simulations_value)) || seed_value != f64(u64(seed_value)) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		simulations, seed := int(simulations_value), u32(seed_value)
		mut rng := mt_seed(seed)
		mut hits := 0
		for _ in 0 .. simulations {
			x, y := mt_random(mut rng), mt_random(mut rng)
			if x * x + y * y <= 1.0 { hits++ }
		}
		output[0] = f64(4 * hits) / f64(simulations)
		return 1
	}
}
