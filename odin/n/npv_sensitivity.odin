package npv_sensitivity

import "core:c"
import "core:math"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
npv_sensitivity :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	nv, rv := input[0], input[1]
	if nv < 0 || nv > 64 || rv < 0 || rv > 32 do return -1
	n, rates := usize(nv), usize(rv)
	if length != 2+n+rates do return -1
	for t: usize = 0; t < n; t += 1 { if input[2+t] < -1000000 || input[2+t] > 1000000 do return -1 }
	for r: usize = 0; r < rates; r += 1 { if input[2+n+r] < 0 || input[2+n+r] > 1000 do return -1 }
	if capacity < rates*8 || (rates > 0 && output == nil) do return -2
	for r: usize = 0; r < rates; r += 1 {
		rate := f64(input[2+n+r])/10000.0
		total := 0.0
		for t: usize = 0; t < n; t += 1 { term := f64(input[2+t])/math.pow_f64(1.0+rate,f64(t)); total += term }
		put_f64_le(output,r*8,total)
	}
	return i64(rates*8)
}
