module kth_element_finder

const invalid_result = i64(-9223372036854775807) - 1

fn sift_down(mut heap []i64, root0 int, min_heap bool) {
	mut root := root0
	for {
		mut best := root
		left := root * 2 + 1
		right := left + 1
		if left < heap.len {
			if (min_heap && heap[left] < heap[best]) || (!min_heap && heap[left] > heap[best]) { best = left }
		}
		if right < heap.len {
			if (min_heap && heap[right] < heap[best]) || (!min_heap && heap[right] > heap[best]) { best = right }
		}
		if best == root { break }
		heap[root], heap[best] = heap[best], heap[root]
		root = best
	}
}

@[export: 'kth_element_finder']
pub fn kth_element_finder(input &i64, length usize) i64 {
	if length < 4 || length > 259 { return invalid_result }
	mode := unsafe { input[0] }
	n_value := unsafe { input[1] }
	k_value := unsafe { input[2] }
	if (mode != 0 && mode != 1) || n_value < 1 || n_value > 256 || k_value < 1 || k_value > n_value {
		return invalid_result
	}
	n := int(n_value)
	k := int(k_value)
	if length != usize(n + 3) { return invalid_result }
	for i in 0 .. n {
		value := unsafe { input[i + 3] }
		if value < -1_000_000 || value > 1_000_000 { return invalid_result }
	}

	min_heap := mode == 0
	mut heap := []i64{cap: k}
	for i in 0 .. k { heap << unsafe { input[i + 3] } }
	mut start := k / 2
	for start > 0 {
		start--
		sift_down(mut heap, start, min_heap)
	}
	for i in k .. n {
		value := unsafe { input[i + 3] }
		if (min_heap && value > heap[0]) || (!min_heap && value < heap[0]) {
			heap[0] = value
			sift_down(mut heap, 0, min_heap)
		}
	}
	return heap[0]
}
