package directed_perfect_phylogeny

import "core:c"

directed_perfect_phylogeny :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 146 do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > 12 || m0 < 1 || m0 > 12 || length != c.size_t(2+n0*m0) do return -1
	n, m := int(n0), int(m0)
	sets: [12]u16
	for row := 0; row < n; row += 1 {
		for col := 0; col < m; col += 1 {
			bit := input[2+row*m+col]
			if bit != 0 && bit != 1 do return -1
			if bit == 1 do sets[col] |= u16(1) << u(row)
		}
	}
	feasible := true
	for a := 0; a < m; a += 1 {
		for b := a+1; b < m; b += 1 {
			overlap := sets[a] & sets[b]
			if overlap != 0 && overlap != sets[a] && overlap != sets[b] do feasible = false
		}
	}
	if output == nil || capacity < 8 do return -2
	result := i64(0)
	if feasible do result = 1
	bits := cast(u64)result
	for b := 0; b < 8; b += 1 { output[b] = u8((bits >> u64(8*b)) & 255) }
	return 8
}
