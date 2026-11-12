module two_square_sum

const max_q = 8
const max_n = i64(10000)
const max_output_bytes = 6496

fn two_square_sum_integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := value + 1
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

fn two_square_sum_write_u32(output &u8, offset int, value u32) {
	unsafe {
		output[offset] = u8(value)
		output[offset + 1] = u8(value >> 8)
		output[offset + 2] = u8(value >> 16)
		output[offset + 3] = u8(value >> 24)
	}
}

@[export: 'two_square_sum']
pub fn two_square_sum(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_q + 1 { return -1 }
		q64 := input[0]
		if q64 < 1 || q64 > i64(max_q) { return -1 }
		q := int(q64)
		if length != usize(q + 1) { return -1 }

		mut numbers := [8]i64{}
		mut counts := [8]int{}
		mut total_pairs := 0
		for query in 0 .. q {
			n := input[query + 1]
			if n < 0 || n > max_n { return -1 }
			numbers[query] = n
			mut a := i64(0)
			for a * a <= n {
				remainder := n - a * a
				b := two_square_sum_integer_sqrt(remainder)
				if b * b == remainder { counts[query]++ }
				a++
			}
			total_pairs += counts[query]
		}

		required := 4 * (q + 2 * total_pairs)
		if output == nil || capacity < usize(required) || required > max_output_bytes { return -2 }
		mut offset := 0
		for query in 0 .. q {
			two_square_sum_write_u32(output, offset, u32(counts[query]))
			offset += 4
			n := numbers[query]
			mut a := i64(0)
			for a * a <= n {
				remainder := n - a * a
				b := two_square_sum_integer_sqrt(remainder)
				if b * b == remainder {
					two_square_sum_write_u32(output, offset, u32(a))
					two_square_sum_write_u32(output, offset + 4, u32(b))
					offset += 8
				}
				a++
			}
		}
		return i64(offset)
	}
}
