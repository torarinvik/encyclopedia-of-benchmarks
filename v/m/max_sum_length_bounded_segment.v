@[export: 'max_sum_length_bounded_segment']
pub fn max_sum_length_bounded_segment(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 35 { return -1 }
		n64 := input[0]
		lower64 := input[1]
		upper64 := input[2]
		if n64 < 1 || n64 > 32 || lower64 < 1 || upper64 < lower64 || upper64 > n64 || length != usize(3+n64) { return -1 }
		n, lower, upper := int(n64), int(lower64), int(upper64)
		mut prefix := []i64{len: n+1, init: 0}
		for i in 0 .. n {
			value := input[3+i]
			if value < -10000 || value > 10000 { return -1 }
			prefix[i+1] = prefix[i] + value
		}
		if output == nil || capacity < 24 { return -2 }
		mut deque := []int{len: n+1, init: 0}
		mut head, mut tail := 0, 0
		mut best_sum := i64(0)
		mut best_start, mut best_end := 0, 0
		mut have_best := false
		for end in lower .. n+1 {
			added := end-lower
			for tail > head && prefix[deque[tail-1]] > prefix[added] { tail-- }
			deque[tail] = added
			tail++
			earliest := if end > upper { end-upper } else { 0 }
			for head < tail && deque[head] < earliest { head++ }
			start := deque[head]
			total := prefix[end]-prefix[start]
			if !have_best || total > best_sum || (total == best_sum &&
				(start < best_start || (start == best_start && end < best_end))) {
				best_sum, best_start, best_end, have_best = total, start, end, true
			}
		}
		values := [3]i64{best_sum, i64(best_start), i64(best_end)}
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return 24
	}
}
