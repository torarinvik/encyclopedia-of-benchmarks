package number_container_system

import "core:c"

@(export)
number_container_system :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < c.size_t(1) || n > c.size_t(97) do return -1
	if v[0] < 0 || v[0] > 32 || n != c.size_t(1+3*int(v[0])) do return -1
	values: [64]i64; present: [64]bool; buf: [128]u8; used := 0
	for i := 0; i < int(v[0]); i += 1 {
		op, a, b := v[1+3*i], v[2+3*i], v[3+3*i]
		if op == 0 { if a < 0 || a > 63 || b < -100 || b > 100 do return -1; values[int(a)] = b; present[int(a)] = true }
		else if op == 1 {
			if a < -100 || a > 100 || b != 0 do return -1
			found: i64 = -1; for j := 0; j < 64; j += 1 { if present[j] && values[j] == a { found = i64(j); break } }
			if used > 0 { buf[used] = ','; used += 1 }
			if found < 0 { buf[used] = '-'; used += 1; found = -found }
			var digits: [3]u8; k := 0; for { digits[k] = u8('0'+found%10); k += 1; found /= 10; if found == 0 do break }; for k > 0 { k -= 1; buf[used] = digits[k]; used += 1 }
		} else { return -1 }
	}
	if out == nil || cap < c.size_t(used) do return -2
	for i := 0; i < used; i += 1 { out[i] = buf[i] }
	return i64(used)
}
