module npb_is

const total_keys = 1 << 20
const max_key = 1 << 16
const num_buckets = 1 << 10
const max_iterations = 10
const max_passes = 10
const test_indices = [5]u32{ 357773, 934767, 875723, 898999, 404505 }
const baseline_ranks = [5]u32{ 1249, 11698, 1039987, 1043896, 1048018 }

// V requires the build command to enable globals for these class-W buffers.
__global (
	mut key_array = [1048576]u32{}
	mut key_buff2 = [1048576]u32{}
	mut key_buff1 = [65536]u32{}
	mut bucket_size = [1024]u32{}
	mut bucket_ptrs = [1024]u32{}
)

fn next_state(state u64) u64 {
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

fn expected_rank(index int, iteration u32) u32 {
	if index < 2 { return u32(i64(baseline_ranks[index]) + i64(iteration) - 2) }
	return baseline_ranks[index] - iteration
}

fn decimal_width(value u32) int {
	mut remaining := value
	mut width := 1
	for remaining >= 10 {
		remaining /= 10
		width++
	}
	return width
}

fn required_output_bytes(pass_count u32) int {
	mut required := 0
	for iteration in u32(1) .. pass_count + 1 {
		for test in 0 .. 5 { required += decimal_width(expected_rank(test, iteration)) }
		required += 5
	}
	return required + decimal_width(5 * pass_count + 1) + 1
}

fn append_decimal(value u32, mut output &u8, mut position int) {
	mut reversed := [10]u8{}
	mut count := 0
	mut remaining := value
	for {
		reversed[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { output[position] = reversed[count] }
		position++
	}
}

fn generate_keys() {
	mut state := u64(314159265)
	for index in 0 .. total_keys {
		mut four_state_sum := u64(0)
		for _ in 0 .. 4 {
			state = next_state(state)
			four_state_sum += state
		}
		key_array[index] = u32(four_state_sum >> 32)
	}
}

fn rank_pass(iteration u32, mut partials [5]u32) {
	key_array[iteration] = iteration
	key_array[iteration + max_iterations] = u32(max_key) - iteration
	for bucket in 0 .. num_buckets { bucket_size[bucket] = 0 }
	for index in 0 .. total_keys { bucket_size[key_array[index] >> 6]++ }
	bucket_ptrs[0] = 0
	for bucket in 1 .. num_buckets { bucket_ptrs[bucket] = bucket_ptrs[bucket - 1] + bucket_size[bucket - 1] }
	for index in 0 .. total_keys {
		key := key_array[index]
		bucket := key >> 6
		key_buff2[bucket_ptrs[bucket]] = key
		bucket_ptrs[bucket]++
	}
	for key in 0 .. max_key { key_buff1[key] = 0 }
	for index in 0 .. total_keys { key_buff1[key_buff2[index]]++ }
	for key in 1 .. max_key { key_buff1[key] += key_buff1[key - 1] }
	for test in 0 .. 5 {
		key := key_array[test_indices[test]]
		partials[test] = if key == 0 { u32(0) } else { key_buff1[key - 1] }
	}
}

fn full_verify() bool {
	for index in 0 .. total_keys {
		key := key_buff2[index]
		bucket_index := int(key)
		key_buff1[bucket_index]--
		key_array[key_buff1[bucket_index]] = key
	}
	for index in 1 .. total_keys {
		if key_array[index - 1] > key_array[index] { return false }
	}
	return true
}

@[export: 'npb_is']
pub fn npb_is(pass_count i64, mut output &u8, output_capacity usize) i64 {
	if pass_count < 1 || pass_count > max_passes { return -1 }
	passes := u32(pass_count)
	required := required_output_bytes(passes)
	if output == nil || output_capacity < usize(required) { return -2 }

	generate_keys()
	mut partials := [5]u32{}
	rank_pass(1, mut partials) // Untimed source warm-up.
	mut passed_verification := u32(0)
	mut position := 0
	for iteration in u32(1) .. passes + 1 {
		rank_pass(iteration, mut partials)
		for test in 0 .. 5 {
			if partials[test] == expected_rank(test, iteration) { passed_verification++ }
			append_decimal(partials[test], mut output, mut position)
			if test + 1 < 5 {
				unsafe { output[position] = u8(',') }
				position++
			}
		}
		unsafe { output[position] = 10 }
		position++
	}
	if full_verify() { passed_verification++ }
	if passed_verification != 5 * passes + 1 { passed_verification = 0 }
	append_decimal(passed_verification, mut output, mut position)
	unsafe { output[position] = 10 }
	position++
	return i64(position)
}
