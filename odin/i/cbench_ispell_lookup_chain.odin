package cbench_ispell_lookup_chain

import "core:c"

ihash :: proc "contextless" (a: [^]i64, start, size, modulus: int) -> int {
	h: u32 = 0
	first := min(size, 4)
	for i := 0; i < first; i += 1 { h = (h << 8) | u32(a[start+i]-32) }
	for i := first; i < size; i += 1 { h = ((h << 5) | (h >> 27)) ^ u32(a[start+i]-32) }
	return int(h % u32(modulus))
}

@(export)
cbench_ispell_lookup_chain :: proc "c" (a: [^]i64, length: c.size_t) -> i64 {
	if a == nil || length < 3 || length > 108 do return -1
	if a[0] < 1 || a[0] > 8 || a[1] < 1 || a[1] > 8 || a[2] < 0 || a[2] > 8 do return -1
	m,q,n := int(a[0]),int(a[1]),int(a[2])
	if length < c.size_t(3+q+m+2*n) do return -1
	h0,nx0,l0 := 3+q,3+q+m,3+q+m+n
	p := l0+n
	for j := 0; j < q; j += 1 { if a[3+j] < 97 || a[3+j] > 122 do return -1 }
	heads: [8]i64 = {}; next: [8]i64 = {}; lens: [8]int = {}; offs: [8]int = {}
	for b := 0; b < m; b += 1 { heads[b] = a[h0+b]; if heads[b] < -1 || heads[b] >= i64(n) do return -1 }
	for i := 0; i < n; i += 1 {
		next[i] = a[nx0+i]
		if next[i] < -1 || next[i] >= i64(n) || a[l0+i] < 1 || a[l0+i] > 8 do return -1
		lens[i] = int(a[l0+i]); if p+lens[i] > int(length) do return -1; offs[i] = p
		for j := 0; j < lens[i]; j += 1 { if a[p+j] < 97 || a[p+j] > 122 do return -1 }
		p += lens[i]
	}
	if p != int(length) do return -1
	seen: [8]bool = {}; count := 0
	for b := 0; b < m; b += 1 { x := heads[b]; for x != -1 { i := int(x); if seen[i] do return -1; seen[i] = true; count += 1; if ihash(a,offs[i],lens[i],m) != b do return -1; x = next[i] } }
	if count != n do return -1
	b := ihash(a,3,q,m); x := heads[b]
	for x != -1 { i := int(x); if lens[i] == q { j := 0; for j < q && a[offs[i]+j] == a[3+j] { j += 1 }; if j == q do return i64(i+1) }; x = next[i] }
	return 0
}
