package pi_monte_carlo_estimation

import "core:c"

MT_N :: 624
MT_M :: 397
MT_MASK :: u64(0xffff_ffff)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(3)

Mt19937 :: struct {
	state: [MT_N]u32,
	index: int,
}

mt_seed :: proc "contextless" (seed: u32) -> Mt19937 {
	var rng: Mt19937
	rng.state[0] = 19_650_218
	for index in 1..<MT_N {
		previous := u64(rng.state[index-1])
		mixed := previous ^ (previous >> 30)
		rng.state[index] = u32((1_812_433_253*u64(mixed)+u64(index))&MT_MASK)
	}
	index, key_index := 1, 0
	for _ in 0..<MT_N {
		previous := u64(rng.state[index-1])
		mixed := ((previous^(previous>>30))*1_664_525)&MT_MASK
		value := (u64(rng.state[index])^mixed)+u64(seed)+u64(key_index)
		rng.state[index] = u32(value&MT_MASK)
		index += 1
		key_index += 1
		if index >= MT_N { rng.state[0] = rng.state[MT_N-1]; index = 1 }
		if key_index >= 1 { key_index = 0 }
	}
	for _ in 0..<MT_N-1 {
		previous := u64(rng.state[index-1])
		mixed := ((previous^(previous>>30))*1_566_083_941)&MT_MASK
		value := (u64(rng.state[index])^mixed)-u64(index)
		rng.state[index] = u32(value&MT_MASK)
		index += 1
		if index >= MT_N { rng.state[0] = rng.state[MT_N-1]; index = 1 }
	}
	rng.state[0] = 0x8000_0000
	rng.index = MT_N
	return rng
}

mt_next_u32 :: proc "contextless" (rng: ^Mt19937) -> u32 {
	if rng.index >= MT_N {
		for index in 0..<MT_N-MT_M {
			joined := (rng.state[index]&0x8000_0000)|(rng.state[index+1]&0x7fff_ffff)
			magic := u32(0)
			if joined&1 != 0 { magic = 0x9908_b0df }
			rng.state[index] = rng.state[index+MT_M]^(joined>>1)^magic
		}
		for index in MT_N-MT_M..<MT_N-1 {
			joined := (rng.state[index]&0x8000_0000)|(rng.state[index+1]&0x7fff_ffff)
			magic := u32(0)
			if joined&1 != 0 { magic = 0x9908_b0df }
			rng.state[index] = rng.state[index-(MT_N-MT_M)]^(joined>>1)^magic
		}
		joined := (rng.state[MT_N-1]&0x8000_0000)|(rng.state[0]&0x7fff_ffff)
		magic := u32(0)
		if joined&1 != 0 { magic = 0x9908_b0df }
		rng.state[MT_N-1] = rng.state[MT_M-1]^(joined>>1)^magic
		rng.index = 0
	}
	value := rng.state[rng.index]
	rng.index += 1
	value ^= value>>11
	value ^= (value<<7)&0x9d2c_5680
	value ^= (value<<15)&0xefc6_0000
	value ^= value>>18
	return value
}

mt_random :: proc "contextless" (rng: ^Mt19937) -> f64 {
	high := mt_next_u32(rng)>>5
	low := mt_next_u32(rng)>>6
	return (f64(high)*67_108_864.0+f64(low))*(1.0/9_007_199_254_740_992.0)
}

pi_monte_carlo_estimation :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input_length != 2 do return -1
	simulations_value, seed_value := input[0], input[1]
	if simulations_value != simulations_value || seed_value != seed_value do return -1
	if simulations_value < 1.0 || simulations_value > 100_000.0 || seed_value < 0.0 || seed_value > 4_294_967_295.0 do return -1
	if simulations_value != f64(int(simulations_value)) || seed_value != f64(u64(seed_value)) do return -1
	if output == nil || output_capacity < 1 do return -2
	simulations, seed := int(simulations_value), u32(seed_value)
	rng := mt_seed(seed)
	hits := 0
	for _ in 0..<simulations {
		x, y := mt_random(&rng), mt_random(&rng)
		if x*x+y*y <= 1.0 { hits += 1 }
	}
	output[0] = f64(4*hits)/f64(simulations)
	return 1
}
