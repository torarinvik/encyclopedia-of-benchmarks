module sum_even_after_queries

const max_numbers = 1000
const max_queries = 1000

// Apply updates in order and emit running even sums as little-endian i32s.
@[export: 'sum_even_after_queries']
pub fn sum_even_after_queries(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 5 || length > 4002 { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > max_numbers || values[1] < 1 || values[1] > max_queries { return -1 }
		number_count := int(values[0])
		query_count := int(values[1])
		if length != usize(2 + number_count + 2 * query_count) { return -1 }
		mut working := []i64{len: number_count}
		mut even_sum := i64(0)
		for index in 0 .. number_count {
			value := values[2 + index]
			if value < 1 || value > 1000 { return -1 }
			working[index] = value
			if value % 2 == 0 { even_sum += value }
		}
		for query in 0 .. query_count {
			offset := 2 + number_count + 2 * query
			if values[offset] < -1000 || values[offset] > 1000 ||
				values[offset + 1] < 0 || values[offset + 1] >= i64(number_count) { return -1 }
		}
		output_bytes := usize(query_count * 4)
		if output_capacity < output_bytes { return -2 }
		for query in 0 .. query_count {
			offset := 2 + number_count + 2 * query
			delta := values[offset]
			index := int(values[offset + 1])
			if working[index] % 2 == 0 { even_sum -= working[index] }
			working[index] += delta
			if working[index] % 2 == 0 { even_sum += working[index] }
			bits := u32(i32(even_sum))
			for byte in 0 .. 4 {
				output[query * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
			}
		}
		return i64(query_count)
	}
}
