package npb_is

import "core:c"

TOTAL_KEYS :: 1 << 20
MAX_KEY :: 1 << 16
NUM_BUCKETS :: 1 << 10
MAX_ITERATIONS :: 10
TEST_COUNT :: 5
MAX_PASSES :: 10

key_array: [TOTAL_KEYS]u32
key_buff2: [TOTAL_KEYS]u32
key_buff1: [MAX_KEY]u32
bucket_size: [NUM_BUCKETS]u32
bucket_ptrs: [NUM_BUCKETS]u32
test_indices: [TEST_COUNT]u32 = {357773, 934767, 875723, 898999, 404505}
baseline_ranks: [TEST_COUNT]u32 = {1249, 11698, 1039987, 1043896, 1048018}

next_state :: proc(state: u64) -> u64 {
	two23 := u64(1) << 23
	low_mask := two23 - 1
	state_mask := (u64(1) << 46) - 1
	multiplier_high := u64(1220703125) / two23
	multiplier_low := u64(1220703125) % two23
	x1 := state >> 23
	x2 := state & low_mask
	t1 := multiplier_high * x2 + multiplier_low * x1
	z := t1 & low_mask
	return ((z << 23) + multiplier_low * x2) & state_mask
}

generate_keys :: proc() {
	state := u64(314159265)
	for index := 0; index < TOTAL_KEYS; index += 1 {
		four_state_sum := u64(0)
		for draw := 0; draw < 4; draw += 1 {
			state = next_state(state)
			four_state_sum += state
		}
		key_array[index] = u32(four_state_sum >> 32)
	}
}

expected_rank :: proc(index: int, iteration: u32) -> u32 {
	if index < 2 do return u32(i64(baseline_ranks[index]) + i64(iteration) - 2)
	return baseline_ranks[index] - iteration
}

decimal_width :: proc(value: u32) -> int {
	remaining := value
	width := 1
	for remaining >= 10 {
		remaining /= 10
		width += 1
	}
	return width
}

required_output_bytes :: proc(pass_count: u32) -> int {
	required := 0
	for iteration: u32 = 1; iteration <= pass_count; iteration += 1 {
		for test := 0; test < TEST_COUNT; test += 1 {
			required += decimal_width(expected_rank(test, iteration))
		}
		required += TEST_COUNT // Four commas and LF.
	}
	return required + decimal_width(5*pass_count+1) + 1
}

append_decimal :: proc(value: u32, output: [^]u8, position: int) -> int {
	mut cursor := position
	reversed: [10]u8
	count := 0
	remaining := value
	for {
		reversed[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		output[cursor] = reversed[count]
		cursor += 1
	}
	return cursor
}

rank_pass :: proc(iteration: u32, partials: ^[TEST_COUNT]u32) {
	key_array[iteration] = iteration
	key_array[iteration+MAX_ITERATIONS] = u32(MAX_KEY) - iteration
	for bucket := 0; bucket < NUM_BUCKETS; bucket += 1 do bucket_size[bucket] = 0
	for index := 0; index < TOTAL_KEYS; index += 1 do bucket_size[key_array[index] >> 6] += 1
	bucket_ptrs[0] = 0
	for bucket := 1; bucket < NUM_BUCKETS; bucket += 1 {
		bucket_ptrs[bucket] = bucket_ptrs[bucket-1] + bucket_size[bucket-1]
	}
	for index := 0; index < TOTAL_KEYS; index += 1 {
		key := key_array[index]
		bucket := key >> 6
		key_buff2[bucket_ptrs[bucket]] = key
		bucket_ptrs[bucket] += 1
	}
	for key := 0; key < MAX_KEY; key += 1 do key_buff1[key] = 0
	for index := 0; index < TOTAL_KEYS; index += 1 do key_buff1[key_buff2[index]] += 1
	for key := 1; key < MAX_KEY; key += 1 do key_buff1[key] += key_buff1[key-1]
	for test := 0; test < TEST_COUNT; test += 1 {
		key := key_array[test_indices[test]]
		partials[test] = if key == 0 do 0 else key_buff1[key-1]
	}
}

full_verify :: proc() -> bool {
	for index := 0; index < TOTAL_KEYS; index += 1 {
		key := key_buff2[index]
		key_buff1[key] -= 1
		key_array[key_buff1[key]] = key
	}
	for index := 1; index < TOTAL_KEYS; index += 1 {
		if key_array[index-1] > key_array[index] do return false
	}
	return true
}

@(export, link_name="npb_is")
npb_is :: proc "c" (pass_count: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if pass_count < 1 || pass_count > MAX_PASSES do return -1
	passes := u32(pass_count)
	required := required_output_bytes(passes)
	if output == nil || output_capacity < c.size_t(required) do return -2

	generate_keys()
	partials: [TEST_COUNT]u32
	rank_pass(1, &partials) // Untimed source warm-up.
	passed_verification := u32(0)
	position := 0
	for iteration: u32 = 1; iteration <= passes; iteration += 1 {
		rank_pass(iteration, &partials)
		for test := 0; test < TEST_COUNT; test += 1 {
			if partials[test] == expected_rank(test, iteration) do passed_verification += 1
			position = append_decimal(partials[test], output, position)
			if test+1 < TEST_COUNT {
				output[position] = u8(',')
				position += 1
			}
		}
		output[position] = u8('\n')
		position += 1
	}
	if full_verify() do passed_verification += 1
	if passed_verification != 5*passes+1 do passed_verification = 0
	position = append_decimal(passed_verification, output, position)
	output[position] = u8('\n')
	position += 1
	return i64(position)
}
