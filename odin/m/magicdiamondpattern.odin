package magicdiamondpattern

import "core:c"

@(export)
magicdiamondpattern :: proc "c" (n: i64, out: [^]u8, capacity: c.size_t) -> i64 {
	msg := "       ...       ....        nothing printing :("
	if n > 45 do return -1
	if n <= 0 {
		if out == nil || capacity < c.size_t(len(msg)) do return -2
		for i := 0; i < len(msg); i += 1 { out[i] = msg[i] }
		return i64(len(msg))
	}
	s := int(n)
	need := 3*s*s + 4*s
	if out == nil || capacity < c.size_t(need) do return -2
	p := 0
	for i := 0; i < s; i += 1 {
		for j := 0; j < s-i-1; j += 1 { out[p] = ' '; p += 1 }
		for j := 0; j < i+1; j += 1 { out[p] = '*'; p += 1; out[p] = ' '; p += 1 }
		out[p] = '\n'; p += 1
	}
	for i := s; i > 0; i -= 1 {
		for j := 0; j < i; j += 1 { out[p] = '*'; p += 1; out[p] = ' '; p += 1 }
		out[p] = '\n'; p += 1
		for j := 0; j < s-i+1; j += 1 { out[p] = ' '; p += 1 }
	}
	return i64(p)
}
