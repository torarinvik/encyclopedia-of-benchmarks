package median_of_three_quick_sorter

import "core:c"

median_of_three :: proc "contextless" (a, b, c: i64) -> i64 {
	if a <= b {
		if b <= c do return b
		if a <= c do return c
		return a
	}
	if b >= c do return b
	if a >= c do return c
	return a
}

partition_range :: proc "contextless" (values: [^]i64, left, right: c.size_t) -> c.size_t {
	middle := left + (right - left) / 2
	pivot := median_of_three(values[left], values[middle], values[right])
	nleft := left
	nright := right
	for {
		for values[nleft] < pivot { nleft += 1 }
		for values[nright] > pivot { nright -= 1 }
		if nleft >= nright do return nright
		temporary := values[nleft]
		values[nleft] = values[nright]
		values[nright] = temporary
		nleft += 1
		nright -= 1
	}
}

sort_range :: proc "contextless" (values: [^]i64, left, right: c.size_t) {
	if left >= right do return
	pivot := partition_range(values, left, right)
	sort_range(values, left, pivot)
	sort_range(values, pivot + 1, right)
}

@(export)
median_of_three_quick_sorter :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 do sort_range(values, 0, length - 1)
}
