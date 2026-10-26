package approximate_tandem_squares

import "core:c"

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[at*8+b] = u8((bits >> u64(8*b)) & 255) }
}

approximate_tandem_squares :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 34 do return -1
	n0, budget := input[0], input[1]
	if n0 < 2 || n0 > 32 || budget < 0 || budget > 8 || length != c.size_t(n0+2) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 3 do return -1 }
	records: [768]i64
	count := 0
	for start := 0; start < n; start += 1 {
		for period := 1; 2*period <= n-start; period += 1 {
			mismatches := i64(0)
			for i := 0; i < period; i += 1 {
				if input[2+start+i] != input[2+start+period+i] do mismatches += 1
			}
			if mismatches <= budget {
				records[3*count] = i64(start); records[3*count+1] = i64(period); records[3*count+2] = mismatches
				count += 1
			}
		}
	}
	bytes := 8 * (1 + 3 * count)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(count))
	for i := 0; i < 3*count; i += 1 { put_i64(output, 1+i, records[i]) }
	return i64(bytes)
}
