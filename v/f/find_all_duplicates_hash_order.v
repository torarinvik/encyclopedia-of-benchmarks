module find_all_duplicates_hash_order

const max_length = 1024
const table_size = 2048

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & u64(255)) }
	}
}

@[export: 'find_all_duplicates_hash_order']
pub fn find_all_duplicates_hash_order(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > max_length || (length > 0 && unsafe { values == nil }) { return -1 }
	unsafe {
		mut keys := [table_size]i64{}
		mut counts := [table_size]u16{}
		mut insertion_order := [max_length]int{}
		mut unique_count := 0
		for index in 0 .. int(length) {
			value := values[index]
			mut slot := int(value % i64(table_size))
			if slot < 0 { slot += table_size }
			for counts[slot] != 0 && keys[slot] != value { slot = (slot + 1) % table_size }
			if counts[slot] == 0 {
				keys[slot] = value
				counts[slot] = 1
				insertion_order[unique_count] = slot
				unique_count++
			} else {
				counts[slot]++
			}
		}

		mut duplicate_count := 0
		for index in 0 .. unique_count {
			if counts[insertion_order[index]] > 1 { duplicate_count++ }
		}
		if duplicate_count == 0 { return 0 }
		required_bytes := usize(duplicate_count * 8)
		if output_capacity < required_bytes || output == nil { return -2 }

		mut written := 0
		for index in 0 .. unique_count {
			slot := insertion_order[index]
			if counts[slot] > 1 {
				store_i64_le(mut output, written * 8, keys[slot])
				written++
			}
		}
		return i64(duplicate_count)
	}
}
