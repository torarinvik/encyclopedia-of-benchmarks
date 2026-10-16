package prefix_to_infix

import "core:c"

get16 :: proc "contextless" (p: [^]u8, i: int) -> int { return int(p[i]) | (int(p[i + 1]) << 8) }
put16 :: proc "contextless" (p: [^]u8, i, x: int) { p[i] = u8(x); p[i + 1] = u8(x >> 8) }
letter :: proc "contextless" (x: i64) -> bool { return (x >= 65 && x <= 90) || (x >= 97 && x <= 122) }
operator :: proc "contextless" (x: i64) -> bool { return x == 43 || x == 45 || x == 42 || x == 47 || x == 94 }

@(export)
prefix_to_infix :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 64 || v[0] < 0 || v[0] > 63 || n != c.size_t(v[0] + 1) do return -1
	if out == nil || cap < 8192 do return -2
	count := int(v[0]); if count == 0 do return 0
	if count == 1 { if !letter(v[1]) do return -1; out[0] = u8(v[1]); return 1 }
	stack, scratch := 0, 256
	for i := count; i > 0; i -= 1 {
		x := v[i]
		if operator(x) {
			if stack < 2 do return -1
			l, r := stack - 2, stack - 1
			ls, ll := get16(out, l * 4), get16(out, l * 4 + 2)
			rs, rl := get16(out, r * 4), get16(out, r * 4 + 2)
			start := scratch; out[scratch] = u8('('); scratch += 1
			for j := 0; j < rl; j += 1 { out[scratch] = out[rs + j]; scratch += 1 }
			out[scratch] = u8(x); scratch += 1
			for j := 0; j < ll; j += 1 { out[scratch] = out[ls + j]; scratch += 1 }
			out[scratch] = u8(')'); scratch += 1
			put16(out, l * 4, start); put16(out, l * 4 + 2, scratch - start); stack -= 1
		} else {
			if !letter(x) do return -1
			put16(out, stack * 4, scratch); put16(out, stack * 4 + 2, 1); out[scratch] = u8(x); scratch += 1; stack += 1
		}
		if scratch > int(cap) do return -2
	}
	if stack != 1 do return -1
	start, size := get16(out, 0), get16(out, 2)
	for i := 0; i < size; i += 1 { out[i] = out[start + i] }
	return i64(size)
}
