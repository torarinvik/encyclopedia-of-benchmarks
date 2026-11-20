package minimum_unfairness_k_selection

import "core:c"

MAX_N :: 64
MIN_VALUE :: i64(-1_000_000_000)
MAX_VALUE :: i64(1_000_000_000)

muks_sift_down :: proc(values: []i64, root_start, ending: int) {
	root := root_start
	for root < ending / 2 {
		child := root * 2 + 1
		if child + 1 < ending && values[child] < values[child + 1] { child += 1 }
		if values[root] >= values[child] { break }
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

muks_heap_sort :: proc(values: []i64) {
	start := len(values) / 2
	for start > 0 {
		start -= 1
		muks_sift_down(values, start, len(values))
	}
	ending := len(values)
	for ending > 1 {
		ending -= 1
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		muks_sift_down(values, 0, ending)
	}
}

@(export)
minimum_unfairness_k_selection :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 4 || length > c.size_t(MAX_N + 2) do return -1
	n_value, k_value := packed[0], packed[1]
	if n_value < 2 || n_value > MAX_N || k_value < 2 || k_value > n_value || length != c.size_t(n_value + 2) do return -1

	n, k := int(n_value), int(k_value)
	var sorted: [MAX_N]i64
	for index in 0..<n {
		value := packed[index+2]
		if value < MIN_VALUE || value > MAX_VALUE do return -1
		sorted[index] = value
	}
	muks_heap_sort(sorted[:n])

	best := i64(2_000_000_001)
	for first := 0; first <= n-k; first += 1 {
		width := sorted[first+k-1] - sorted[first]
		if width < best do best = width
	}
	return best
}
