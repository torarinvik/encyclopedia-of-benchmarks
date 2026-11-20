package erdos_gallai_graphical_sequence

import "core:c"

MAX_N :: 256
MAX_PARSEABLE_LENGTH :: 258

sift_down :: proc "contextless" (degrees: [^]i64, root_start, end_exclusive: int) {
	root := root_start
	for root < end_exclusive / 2 {
		child := root * 2 + 1
		if child + 1 < end_exclusive && degrees[child] < degrees[child + 1] do child += 1
		if degrees[root] >= degrees[child] do break
		temporary := degrees[root]
		degrees[root] = degrees[child]
		degrees[child] = temporary
		root = child
	}
}

sort_descending :: proc "contextless" (degrees: [^]i64, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(degrees, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		temporary := degrees[0]
		degrees[0] = degrees[ending]
		degrees[ending] = temporary
		sift_down(degrees, 0, ending)
	}
	left := 0
	right := count - 1
	for left < right {
		temporary := degrees[left]
		degrees[left] = degrees[right]
		degrees[right] = temporary
		left += 1
		right -= 1
	}
}

@(export)
erdos_gallai_graphical_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < c.size_t(1) || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	n_word := input[0]
	if n_word < 0 || n_word > i64(MAX_N) do return -1
	n := int(n_word)
	if length != c.size_t(n + 1) do return -1

	degrees: [MAX_N]i64 = {}
	sum: i64 = 0
	for index := 0; index < n; index += 1 {
		degree := input[index + 1]
		if degree < 0 || degree >= n_word do return -1
		degrees[index] = degree
		sum += degree
	}

	if sum % 2 != 0 do return 0
	if n == 0 do return 1

	sort_descending(&degrees[0], n)
	prefix: [MAX_N + 1]i64 = {}
	for index := 0; index < n; index += 1 {
		prefix[index + 1] = prefix[index] + degrees[index]
	}

	for k := 1; k <= n; k += 1 {
		low := k
		high := n
		for low < high {
			middle := low + (high - low) / 2
			if degrees[middle] >= i64(k) {
				low = middle + 1
			} else {
				high = middle
			}
		}
		split := low
		k64 := i64(k)
		rhs := k64*(k64-1) + i64(split-k)*k64 + (prefix[n]-prefix[split])
		if prefix[k] > rhs do return 0
	}
	return 1
}
