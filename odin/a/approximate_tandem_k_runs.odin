package approximate_tandem_k_runs
import "core:c"

MAX_TEXT :: 24
MAX_INPUT :: 26
MAX_OUTPUT :: 34504

max_window_mismatches :: proc(input: [^]i64, start, factor_length, period: int) -> int {
	maximum := 0
	windows := factor_length - 2*period + 1
	for window := 0; window < windows; window += 1 {
		count := 0
		for offset := 0; offset < period; offset += 1 {
			if input[2+start+window+offset] != input[2+start+window+period+offset] { count += 1 }
		}
		if count > maximum { maximum = count }
	}
	return maximum
}
count_records :: proc(input: [^]i64, n, budget: int) -> int {
	count := 0
	for start := 0; start < n; start += 1 {
		remaining := n-start
		for period := 1; 2*period+1 <= remaining; period += 1 {
			for factor_length := 2*period+1; factor_length <= remaining; factor_length += 1 {
				if max_window_mismatches(input,start,factor_length,period) <= budget { count += 1 }
			}
		}
	}
	return count
}
store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
approximate_tandem_k_runs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	n0, budget0 := input[0], input[1]
	if n0 < 3 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 8 || length != c.size_t(n0+2) do return -1
	n, budget := int(n0), int(budget0)
	for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 3 do return -1 }
	count := count_records(input,n,budget)
	bytes := 8*(1+4*count)
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	store_i64_le(output,0,i64(count))
	record := 0
	for start := 0; start < n; start += 1 {
		remaining := n-start
		for period := 1; 2*period+1 <= remaining; period += 1 {
			for factor_length := 2*period+1; factor_length <= remaining; factor_length += 1 {
				errors := max_window_mismatches(input,start,factor_length,period)
				if errors <= budget {
					offset := 8*(1+4*record)
					store_i64_le(output,offset,i64(start))
					store_i64_le(output,offset+8,i64(factor_length))
					store_i64_le(output,offset+16,i64(period))
					store_i64_le(output,offset+24,i64(errors))
					record += 1
				}
			}
		}
	}
	return i64(bytes)
}
