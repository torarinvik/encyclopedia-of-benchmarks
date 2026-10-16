package node_neighbors

import "core:c"

@(export)
node_neighbors :: proc "c" (v: [^]i64, n: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if v == nil || n < 2 || v[0] < 0 || v[0] > 64 || v[1] < 0 || v[1] > 63 || int(n) != 2+2*int(v[0]) do return -1
	seen: [64]bool; buffer: [192]u8; used := 0
	for i := 0; i < int(v[0]); i += 1 {
		a, b := v[2+2*i], v[3+2*i]; if a < 0 || a > 63 || b < 0 || b > 63 do return -1
		neighbor: i64 = -1; if a == v[1] { neighbor = b } else if b == v[1] { neighbor = a }
		if neighbor >= 0 && !seen[int(neighbor)] { seen[int(neighbor)] = true; if used > 0 { buffer[used] = ','; used += 1 }; x := int(neighbor); if x >= 10 { buffer[used] = u8('0'+x/10); used += 1 }; buffer[used] = u8('0'+x%10); used += 1 }
	}
	if used > int(capacity) || (used > 0 && output == nil) do return -2
	for i := 0; i < used; i += 1 { output[i] = buffer[i] }
	return i64(used)
}
