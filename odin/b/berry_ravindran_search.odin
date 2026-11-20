package berry_ravindran_search

import "core:c"

@(export)
berry_ravindran_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 274 do return -2
	if values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16 do return -2
	n := c.size_t(values[0])
	m := c.size_t(values[1])
	if length != 2 + n + m do return -2
	for i := c.size_t(0); i < n + m; i += 1 {
		if values[2 + i] < 0 || values[2 + i] > 15 do return -2
	}
	if m > n do return -1
	p := 2 + n
	shift: [289]c.size_t
	for i := c.size_t(0); i < 289; i += 1 { shift[i] = m + 2 }
	for first := c.size_t(0); first < 17; first += 1 { shift[int(first * 17) + int(values[p])] = m + 1 }
	for i := c.size_t(0); i + 1 < m; i += 1 { shift[int(values[p + i]) * 17 + int(values[p + i + 1])] = m - i }
	for second := c.size_t(0); second < 17; second += 1 { shift[int(values[p + m - 1]) * 17 + int(second)] = 1 }
	start := c.size_t(0)
	for start <= n - m {
		i := c.size_t(0)
		for i < m && values[2 + start + i] == values[p + i] { i += 1 }
		if i == m do return i64(start)
		k := start + m
		if k >= n do break
		first := c.size_t(values[2 + k])
		second := c.size_t(16)
		if k + 1 < n { second = c.size_t(values[2 + k + 1]) }
		start += shift[int(first * 17) + int(second)]
	}
	return -1
}
