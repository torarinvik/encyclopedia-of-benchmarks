module approximate_tandem_k_runs

const max_text = 24
const max_input = 26
const max_output = 34504

fn max_window_mismatches(input []i64, start int, factor_length int, period int) int {
	mut maximum := 0
	windows := factor_length - 2 * period + 1
	for window in 0 .. windows {
		mut count := 0
		for offset in 0 .. period {
			if input[2 + start + window + offset] != input[2 + start + window + period + offset] { count++ }
		}
		if count > maximum { maximum = count }
	}
	return maximum
}
fn count_records(input []i64, n int, budget int) int {
	mut count := 0
	for start in 0 .. n {
		remaining := n - start
		for period in 1 .. (remaining - 1) / 2 + 1 {
			for factor_length in 2 * period + 1 .. remaining + 1 {
				if max_window_mismatches(input, start, factor_length, period) <= budget { count++ }
			}
		}
	}
	return count
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'approximate_tandem_k_runs']
pub fn approximate_tandem_k_runs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		n0 := input[0]
		budget0 := input[1]
		if n0 < 3 || n0 > max_text || budget0 < 0 || budget0 > 8 || length != usize(n0 + 2) { return -1 }
		n := int(n0)
		budget := int(budget0)
		mut values := []i64{len: n + 2, init: 0}
		for i in 0 .. n + 2 { values[i] = input[i] }
		for i in 0 .. n { if values[2 + i] < 0 || values[2 + i] > 3 { return -1 } }
		count := count_records(values, n, budget)
		bytes := 8 * (1 + 4 * count)
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		store_i64_le(mut output, 0, i64(count))
		mut record := 0
		for start in 0 .. n {
			remaining := n - start
			for period in 1 .. (remaining - 1) / 2 + 1 {
				for factor_length in 2 * period + 1 .. remaining + 1 {
					errors := max_window_mismatches(values, start, factor_length, period)
					if errors <= budget {
						offset := 8 * (1 + 4 * record)
						store_i64_le(mut output, offset, i64(start))
						store_i64_le(mut output, offset + 8, i64(factor_length))
						store_i64_le(mut output, offset + 16, i64(period))
						store_i64_le(mut output, offset + 24, i64(errors))
						record++
					}
				}
			}
		}
		return i64(bytes)
	}
}
