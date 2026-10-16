package pig_latin

import "core:c"

@(export)
pig_latin :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != c.size_t(v[0] + 1) do return -1
	count := int(v[0]); if count == 0 do return 0
	if count + 3 > int(cap) || out == nil do return -2
	pivot := count
	for i := 0; i < count; i += 1 {
		x := v[i + 1]; if x >= 65 && x <= 90 do x += 32
		if x < 97 || x > 122 do return -1
		out[i] = u8(x)
		if pivot == count && (x == 97 || x == 101 || x == 105 || x == 111 || x == 117) do pivot = i
	}
	if pivot == count do return -1
	if pivot == 0 { out[count] = 'w'; out[count + 1] = 'a'; out[count + 2] = 'y'; return i64(count + 3) }
	for i := 0; i < pivot; i += 1 { out[count + i] = out[i] }
	for i := 0; i < count - pivot; i += 1 { out[i] = out[pivot + i] }
	out[count] = 'a'; out[count + 1] = 'y'
	return i64(count + 2)
}
