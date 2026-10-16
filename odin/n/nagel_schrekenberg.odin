package nagel_schrekenberg

import "core:c"

@(export)
nagel_schrekenberg :: proc "c" (v: [^]i64, n: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if v == nil || n < 5 || v[0] < 2 || v[0] > 32 || v[1] < 0 || v[1] > 16 || v[2] < 0 || v[2] > 5 || int(n) != int(v[0])+3 do return -1
	cells, steps, vmax := int(v[0]), int(v[1]), v[2]
	row: [32]i64; for i := 0; i < cells; i += 1 { if v[i+3] < -1 || v[i+3] > 5 do return -1; row[i] = v[i+3] }
	need := cells*(steps+1); if need > int(capacity) || output == nil do return -2
	pos := 0; for j := 0; j < cells; j += 1 { output[pos] = u8(row[j]+1); pos += 1 }
	for t := 0; t < steps; t += 1 {
		next: [32]i64
		for i := 0; i < cells; i += 1 { next[i] = -1; if row[i] != -1 {
			distance, j := 0, i+1; for j < cells && row[j] == -1 { distance += 1; j += 1 }
			if j == cells { j = 0; for row[j] == -1 { distance += 1; j += 1 } }
			speed := row[i]+1; if speed > vmax { speed = vmax }; if speed > i64(distance)-1 { speed = i64(distance)-1 }; next[i] = speed
		} }
		moved: [32]i64; for i := 0; i < cells; i += 1 { moved[i] = -1 }
		for i := 0; i < cells; i += 1 { if next[i] != -1 { moved[(i+int(next[i]))%cells] = next[i] } }
		row = moved; for j := 0; j < cells; j += 1 { output[pos] = u8(row[j]+1); pos += 1 }
	}
	return i64(pos)
}
