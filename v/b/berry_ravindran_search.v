module berry_ravindran_search

@[export: 'berry_ravindran_search']
pub fn berry_ravindran_search(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 274 { return -2 }
	nv := unsafe { values[0] }
	mv := unsafe { values[1] }
	if nv < 0 || nv > 256 || mv < 1 || mv > 16 { return -2 }
	n := int(nv)
	m := int(mv)
	if length != usize(2 + n + m) { return -2 }
	for i in 0 .. n + m {
		x := unsafe { values[2 + i] }
		if x < 0 || x > 15 { return -2 }
	}
	if m > n { return -1 }
	p := 2 + n
	mut shift := [289]int{init: m + 2}
	for first in 0 .. 17 { shift[first * 17 + int(unsafe { values[p] })] = m + 1 }
	for i in 0 .. (m - 1) { shift[int(unsafe { values[p + i] }) * 17 + int(unsafe { values[p + i + 1] })] = m - i }
	for second in 0 .. 17 { shift[int(unsafe { values[p + m - 1] }) * 17 + second] = 1 }
	mut start := 0
	for start <= n - m {
		mut i := 0
		for i < m && unsafe { values[2 + start + i] == values[p + i] } { i++ }
		if i == m { return i64(start) }
		k := start + m
		if k >= n { break }
		first := int(unsafe { values[2 + k] })
		second := if k + 1 < n { int(unsafe { values[2 + k + 1] }) } else { 16 }
		start += shift[first * 17 + second]
	}
	return -1
}
