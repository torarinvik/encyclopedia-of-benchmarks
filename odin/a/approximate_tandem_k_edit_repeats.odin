package approximate_tandem_k_edit_repeats
import "core:c"

MAX_TEXT :: 12
MAX_INPUT :: 14
MAX_OUTPUT :: 1592

minimum :: proc(a, b: int) -> int { if a < b { return a }; return b }

edit_distance :: proc(input: [^]i64, a, a_length, b, b_length: int) -> int {
	row: [MAX_TEXT + 1]int
	for j := 0; j <= b_length; j += 1 { row[j] = j }
	for i := 1; i <= a_length; i += 1 {
		diagonal := row[0]
		row[0] = i
		for j := 1; j <= b_length; j += 1 {
			above := row[j]
			deletion := above + 1
			insertion := row[j-1] + 1
			substitution := diagonal
			if input[2+a+i-1] != input[2+b+j-1] { substitution += 1 }
			row[j] = minimum(minimum(deletion, insertion), substitution)
			diagonal = above
		}
	}
	return row[b_length]
}

minimum_edit_cost :: proc(input: [^]i64, start, factor_length: int) -> int {
	best := 1000
	piece_starts: [MAX_TEXT]int
	piece_lengths: [MAX_TEXT]int
	for prefix := 0; prefix <= factor_length; prefix += 1 {
		for suffix := 0; prefix+suffix <= factor_length; suffix += 1 {
			middle := factor_length-prefix-suffix
			if middle < 2 { continue }
			end_mask := 1 << (middle-1)
			for mask := 1; mask < end_mask; mask += 1 {
				segments, previous := 0, 0
				for cut := 1; cut < middle; cut += 1 {
					if (mask & (1 << (cut-1))) != 0 {
						piece_starts[segments] = start+prefix+previous
						piece_lengths[segments] = cut-previous
						segments += 1
						previous = cut
					}
				}
				piece_starts[segments] = start+prefix+previous
				piece_lengths[segments] = middle-previous
				segments += 1
				left := 1000
				for fragment := 0; fragment <= piece_lengths[0]; fragment += 1 {
					cost := edit_distance(input,start,prefix,piece_starts[0]+piece_lengths[0]-fragment,fragment)
					if cost < left { left = cost }
				}
				last := segments-1
				right := 1000
				for fragment := 0; fragment <= piece_lengths[last]; fragment += 1 {
					cost := edit_distance(input,piece_starts[last],fragment,start+factor_length-suffix,suffix)
					if cost < right { right = cost }
				}
				internal := 0
				for i := 0; i+1 < segments; i += 1 {
					internal += edit_distance(input,piece_starts[i],piece_lengths[i],piece_starts[i+1],piece_lengths[i+1])
				}
				total := left+internal+right
				if total < best { best = total }
			}
		}
	}
	return best
}

count_records :: proc(input: [^]i64, n, budget: int) -> int {
	count := 0
	for start := 0; start < n; start += 1 {
		for factor_length := 2; factor_length <= n-start; factor_length += 1 {
			if minimum_edit_cost(input,start,factor_length) <= budget { count += 1 }
		}
	}
	return count
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
approximate_tandem_k_edit_repeats :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n0, budget0 := input[0], input[1]
	if n0 < 2 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 4 || length != c.size_t(n0+2) do return -1
	n, budget := int(n0), int(budget0)
	for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 3 do return -1 }
	count := count_records(input,n,budget)
	bytes := 8*(1+3*count)
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	store_i64_le(output,0,i64(count))
	record := 0
	for start := 0; start < n; start += 1 {
		for factor_length := 2; factor_length <= n-start; factor_length += 1 {
			cost := minimum_edit_cost(input,start,factor_length)
			if cost <= budget {
				offset := 8*(1+3*record)
				store_i64_le(output,offset,i64(start))
				store_i64_le(output,offset+8,i64(factor_length))
				store_i64_le(output,offset+16,i64(cost))
				record += 1
			}
		}
	}
	return i64(bytes)
}
