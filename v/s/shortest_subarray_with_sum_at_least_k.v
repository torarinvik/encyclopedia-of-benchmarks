@[export: 'shortest_subarray_with_sum_at_least_k']
pub fn shortest_subarray_with_sum_at_least_k(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 2 || length > 259 { return -1 }
		target := packed[0]
		count := packed[1]
		if target < -4096 || target > 4096 || count < 0 || count > 256 ||
			length != usize(count) + 2 {
			return -1
		}
		n := int(count)
		mut prefix := []i64{len: n + 1, init: 0}
		for index in 0 .. n {
			value := packed[index + 2]
			if value < -1000 || value > 1000 { return -1 }
			prefix[index + 1] = prefix[index] + value
		}

		mut deque := []int{len: n + 1, init: 0}
		mut head, mut tail := 0, 0
		mut best := n + 1
		for right in 0 .. n + 1 {
			for head < tail && prefix[right] - prefix[deque[head]] >= target {
				width := right - deque[head]
				if width < best { best = width }
				head++
			}
			for head < tail && prefix[right] <= prefix[deque[tail - 1]] {
				tail--
			}
			deque[tail] = right
			tail++
		}
		if best <= n { return i64(best) }
		return 0
	}
}

