module minimum_unfairness_k_selection

const max_n = 64
const min_value = i64(-1_000_000_000)
const max_value = i64(1_000_000_000)

fn muks_sift_down(mut values []i64, root_start int, ending int) {
	mut root := root_start
	for root < ending / 2 {
		mut child := root * 2 + 1
		if child + 1 < ending && values[child] < values[child + 1] { child++ }
		if values[root] >= values[child] { break }
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

fn muks_heap_sort(mut values []i64) {
	mut start := values.len / 2
	for start > 0 {
		start--
		muks_sift_down(mut values, start, values.len)
	}
	mut ending := values.len
	for ending > 1 {
		ending--
		values[0], values[ending] = values[ending], values[0]
		muks_sift_down(mut values, 0, ending)
	}
}

@[export: 'minimum_unfairness_k_selection']
pub fn minimum_unfairness_k_selection(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 4 || length > max_n + 2 { return -1 }
	unsafe {
		n_value := packed[0]
		k_value := packed[1]
		if n_value < 2 || n_value > max_n || k_value < 2 || k_value > n_value || length != usize(n_value + 2) { return -1 }
		n, k := int(n_value), int(k_value)
		mut sorted := []i64{len: n}
		for index in 0 .. n {
			value := packed[index + 2]
			if value < min_value || value > max_value { return -1 }
			sorted[index] = value
		}
		muks_heap_sort(mut sorted)
		mut best := i64(2_000_000_001)
		for first in 0 .. n - k + 1 {
			width := sorted[first + k - 1] - sorted[first]
			if width < best { best = width }
		}
		return best
	}
}
