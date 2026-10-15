package npv

import "core:c"
import "core:math"

@(export)
npv :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	invalid := -1e300
	if input == nil || length < 2 do return invalid
	nv, rate_bp := input[0], input[1]
	if nv < 0 || nv > 64 || rate_bp < 0 || rate_bp > 1000 || length != usize(nv)+2 do return invalid
	n := usize(nv)
	for t: usize = 0; t < n; t += 1 { if input[t+2] < -1000000 || input[t+2] > 1000000 do return invalid }
	rate := f64(rate_bp)/10000.0
	total := 0.0
	for t: usize = 0; t < n; t += 1 {
		term := f64(input[t+2])/math.pow_f64(1.0+rate,f64(t))
		total += term
	}
	return total
}
