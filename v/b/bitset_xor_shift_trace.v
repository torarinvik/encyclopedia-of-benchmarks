fn popcount64(value u64) i32 {
	mut remaining := value
	mut count := i32(0)
	for remaining != 0 {
		remaining &= remaining - 1
		count++
	}
	return count
}

fn store_i32_le(output &u8, offset int, value i32) {
	unsafe {
		mut bits := u32(value)
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'bitset_xor_shift_trace']
pub fn bitset_xor_shift_trace(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 131 { return -1 }
		n64 := input[0]
		q64 := input[1]
		if n64 < 1 || n64 > 4096 || q64 < 0 || q64 > 64 { return -1 }
		n := int(n64)
		q := int(q64)
		word_count := (n + 63) / 64
		shift_offset := 2 + word_count
		if length != usize(shift_offset + q) { return -1 }

		mut words := [64]u64{}
		for word in 0 .. word_count { words[word] = u64(input[2 + word]) }
		tail_bits := n % 64
		tail_mask := if tail_bits == 0 { u64(0) - 1 } else { (u64(1) << tail_bits) - 1 }
		if (words[word_count - 1] & ~tail_mask) != 0 { return -1 }
		for operation in 0 .. q {
			shift := input[shift_offset + operation]
			if shift < -(n64 - 1) || shift > n64 - 1 { return -1 }
		}

		output_bytes := q * 4
		if output_bytes > 0 && (output == nil || capacity < usize(output_bytes)) { return -2 }
		mut counts := [64]i32{}
		for operation in 0 .. q {
			shift := input[shift_offset + operation]
			if shift == 0 {
				for word in 0 .. word_count { words[word] = 0 }
			} else if shift > 0 {
				distance := int(shift)
				whole := distance / 64
				part := distance % 64
				for destination in 0 .. word_count {
					source := destination + whole
					mut shifted := u64(0)
					if source < word_count { shifted = words[source] >> part }
					if part != 0 && source + 1 < word_count { shifted |= words[source + 1] << (64 - part) }
					words[destination] ^= shifted
				}
			} else {
				distance := int(-shift)
				whole := distance / 64
				part := distance % 64
				for reverse_index in 0 .. word_count {
					destination := word_count - 1 - reverse_index
					source := destination - whole
					mut shifted := u64(0)
					if source >= 0 { shifted = words[source] << part }
					if part != 0 && source > 0 { shifted |= words[source - 1] >> (64 - part) }
					words[destination] ^= shifted
				}
			}
			words[word_count - 1] &= tail_mask
			mut count := i32(0)
			for word in 0 .. word_count { count += popcount64(words[word]) }
			counts[operation] = count
		}
		for operation in 0 .. q { store_i32_le(output, operation * 4, counts[operation]) }
		return i64(output_bytes)
	}
}
