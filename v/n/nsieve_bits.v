module nsieve_bits

const max_limit = i64(1_000_000)
const max_words = 15626

fn count_primes(limit i64) i64 {
	mut bits := [max_words]u64{}
	for word in 0 .. max_words { bits[word] = u64(0xffffffffffffffff) }
	mut count := i64(0)
	mut value := i64(2)
	for value <= limit {
		word := int(value >> 6)
		mask := u64(1) << u64(value & 63)
		if bits[word] & mask != 0 {
			count++
			mut multiple := value + value
			for multiple <= limit {
				multiple_word := int(multiple >> 6)
				multiple_mask := u64(1) << u64(multiple & 63)
				if bits[multiple_word] & multiple_mask != 0 { bits[multiple_word] ^= multiple_mask }
				multiple += value
			}
		}
		value++
	}
	return count
}

fn put_u64_le(mut output &u8, offset int, value u64) {
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(value >> u64(byte * 8)) } }
}

@[export: 'benchmarkgame_nsieve_bits']
pub fn benchmarkgame_nsieve_bits(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	limit := unsafe { input[0] }
	if limit < 0 || limit > max_limit { return -1 }
	if unsafe { output == nil } || capacity < 24 { return -2 }
	for pass in 0 .. 3 { put_u64_le(mut output, pass * 8, u64(count_primes(limit >> pass))) }
	return 24
}
