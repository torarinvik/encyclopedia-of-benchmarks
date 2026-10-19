package cbench_automotive_bitcount

MAX_ITERATIONS :: 1_125_000
NIBBLE_BITS :: [16]i32{0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4}
INITIAL_SEEDS :: [7]u32{1, 1, 1, 1, 1, 1, 1}

count_kernighan :: proc(value_input: u32) -> i32 {
	value := value_input
	count: i32 = 0
	for value != 0 {
		value &= value - 1
		count += 1
	}
	return count
}

count_parallel :: proc(value_input: u32) -> i32 {
	value := value_input
	value = ((value & 0xAAAAAAAA) >> 1) + (value & 0x55555555)
	value = ((value & 0xCCCCCCCC) >> 2) + (value & 0x33333333)
	value = ((value & 0xF0F0F0F0) >> 4) + (value & 0x0F0F0F0F)
	value = ((value & 0xFF00FF00) >> 8) + (value & 0x00FF00FF)
	value = ((value & 0xFFFF0000) >> 16) + (value & 0x0000FFFF)
	return i32(value)
}

count_recursive_nybbles :: proc(value: u32) -> i32 {
	count := NIBBLE_BITS[value & 0xF]
	if value >> 4 == 0 do return count
	return count + count_recursive_nybbles(value >> 4)
}

count_fixed_nybbles :: proc(value: u32) -> i32 {
	count: i32 = 0
	for shift := u32(0); shift < 32; shift += 4 {
		count += NIBBLE_BITS[(value >> shift) & 0xF]
	}
	return count
}

count_byte :: proc(value: u32) -> i32 {
	return NIBBLE_BITS[value & 0xF] + NIBBLE_BITS[(value >> 4) & 0xF]
}

count_bw_bytes :: proc(value: u32) -> i32 {
	return count_byte(value) + count_byte(value >> 8) + count_byte(value >> 24) + count_byte(value >> 16)
}

count_ar_bytes :: proc(value: u32) -> i32 {
	count: i32 = 0
	for index := u32(0); index < 4; index += 1 {
		count += count_byte(value >> (index * 8))
	}
	return count
}

count_shift_test :: proc(value_input: u32) -> i32 {
	value := value_input
	count: i32 = 0
	for bit := 0; bit < 64 && value != 0; bit += 1 {
		count += i32(value & 1)
		value >>= 1
	}
	return count
}

count_selected :: proc(algorithm: int, value: u32) -> i32 {
	if algorithm == 0 do return count_kernighan(value)
	if algorithm == 1 do return count_parallel(value)
	if algorithm == 2 do return count_recursive_nybbles(value)
	if algorithm == 3 do return count_fixed_nybbles(value)
	if algorithm == 4 do return count_bw_bytes(value)
	if algorithm == 5 do return count_ar_bytes(value)
	return count_shift_test(value)
}

@(export)
cbench_automotive_bitcount :: proc "c" (iterations: i64) -> i64 {
	if iterations < 0 || iterations > MAX_ITERATIONS do return -1
	result: i64 = 0
	for algorithm := 0; algorithm < 7; algorithm += 1 {
		seed := INITIAL_SEEDS[algorithm]
		total: i64 = 0
		for iteration := i64(0); iteration < iterations; iteration += 1 {
			total += i64(count_selected(algorithm, seed))
			seed += 13
		}
		result += i64(algorithm + 1) * total
	}
	return result
}
