module automotive_bitcount

const max_iterations = i64(1_125_000)
const nibble_bits = [16]i32{0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4}
const initial_seeds = [7]u32{16839, 18985, 21520, 3905, 10113, 8672, 21285}

fn count_kernighan(value_input u32) i32 {
	mut value := value_input
	mut count := i32(0)
	for value != 0 {
		value &= value - 1
		count++
	}
	return count
}

fn count_parallel(value_input u32) i32 {
	mut value := value_input
	value = ((value & u32(0xAAAAAAAA)) >> 1) + (value & u32(0x55555555))
	value = ((value & u32(0xCCCCCCCC)) >> 2) + (value & u32(0x33333333))
	value = ((value & u32(0xF0F0F0F0)) >> 4) + (value & u32(0x0F0F0F0F))
	value = ((value & u32(0xFF00FF00)) >> 8) + (value & u32(0x00FF00FF))
	value = ((value & u32(0xFFFF0000)) >> 16) + (value & u32(0x0000FFFF))
	return i32(value)
}

fn count_recursive_nybbles(value u32) i32 {
	count := nibble_bits[int(value & 0xF)]
	if value >> 4 == 0 { return count }
	return count + count_recursive_nybbles(value >> 4)
}

fn count_fixed_nybbles(value u32) i32 {
	mut count := i32(0)
	for shift in 0 .. 32 {
		if shift % 4 == 0 { count += nibble_bits[int((value >> shift) & 0xF)] }
	}
	return count
}

fn count_byte(value u32) i32 {
	return nibble_bits[int(value & 0xF)] + nibble_bits[int((value >> 4) & 0xF)]
}

fn count_bw_bytes(value u32) i32 {
	return count_byte(value) + count_byte(value >> 8) + count_byte(value >> 24) + count_byte(value >> 16)
}

fn count_ar_bytes(value u32) i32 {
	mut count := i32(0)
	for index in 0 .. 4 { count += count_byte(value >> (index * 8)) }
	return count
}

fn count_shift_test(value_input u32) i32 {
	mut value := value_input
	mut count := i32(0)
	for bit in 0 .. 64 {
		if value == 0 { break }
		count += i32(value & 1)
		value >>= 1
	}
	return count
}

fn count_selected(algorithm int, value u32) i32 {
	if algorithm == 0 { return count_kernighan(value) }
	if algorithm == 1 { return count_parallel(value) }
	if algorithm == 2 { return count_recursive_nybbles(value) }
	if algorithm == 3 { return count_fixed_nybbles(value) }
	if algorithm == 4 { return count_bw_bytes(value) }
	if algorithm == 5 { return count_ar_bytes(value) }
	return count_shift_test(value)
}

@[export: 'automotive_bitcount']
pub fn automotive_bitcount(iterations i64) i64 {
	if iterations < 0 || iterations > max_iterations { return -1 }
	mut result := i64(0)
	for algorithm in 0 .. 7 {
		mut seed := initial_seeds[algorithm]
		mut total := i64(0)
		mut iteration := i64(0)
		for iteration < iterations {
			total += i64(count_selected(algorithm, seed))
			seed += u32(13)
			iteration++
		}
		result += i64(algorithm + 1) * total
	}
	return result
}
