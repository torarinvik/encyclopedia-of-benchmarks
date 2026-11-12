module enumerate_quotients

@[export: 'enumerate_quotients']
pub fn enumerate_quotients(value i64, output &u8, output_capacity usize) i64 {
	if value < 1 || value > 100_000 { return -1 }
	n := u64(value)
	mut count := usize(0)
	mut left := u64(1)
	for left <= n {
		quotient := n / left
		count++
		left = n / quotient + 1
	}
	byte_count := (count + 1) * 8
	if unsafe { output == nil } || output_capacity < byte_count { return -2 }
	count_word := u64(count)
	for byte_index in 0 .. 8 {
		unsafe { output[byte_index] = u8((count_word >> u64(byte_index * 8)) & 255) }
	}
	mut index := usize(0)
	left = 1
	for left <= n {
		quotient := n / left
		for byte_index in 0 .. 8 {
			unsafe { output[(index + 1) * 8 + usize(byte_index)] = u8((quotient >> u64(byte_index * 8)) & 255) }
		}
		index++
		left = n / quotient + 1
	}
	return i64(byte_count)
}
