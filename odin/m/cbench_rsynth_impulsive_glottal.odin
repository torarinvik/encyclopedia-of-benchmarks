package cbench_rsynth_impulsive_glottal

import "core:c"
import "core:math"

@(export, link_name="cbench_rsynth_impulsive_glottal_sample")
cbench_rsynth_impulsive_glottal_sample :: proc "c" (input: [^]f64, n: c.size_t, output: [^]f64, cap: c.size_t) -> i64 {
	if input == nil || n == 0 || n > 3 do return -1
	for i := 0; i < int(n); i += 1 { if input[i] != input[i] || math.abs(input[i]) > 1.0e300 do return -1 }
	if n != 2 || input[0] < 40 || input[0] > 263 || input[0] != f64(int(input[0])) || input[1] < 0 || input[1] > 299 || input[1] != f64(int(input[1])) do return -1
	open, target, rate := int(input[0]), int(input[1]), 8000
	minus_pi := f32(-math.PI / f64(rate))
	two_pi := f32(-2.0 * f64(minus_pi))
	bw := rate / open
	r := f32(math.exp(f64(minus_pi) * f64(bw)))
	c := f32(-(r * r))
	b := f32(f64(r) * math.cos(f64(two_pi)*0.0) * 2.0)
	a := f32(1.0 - f64(b) - f64(c))
	t := f32(f64(open) * 0.00833)
	a = f32(a * (t * t))
	p1, p2, result: f32 = 0, 0, 0
	for i := 0; i <= target; i += 1 {
		impulse: f32 = 0
		if i == 1 do impulse = 13_000_000
		if i == 2 do impulse = -13_000_000
		x := f32(a * impulse)
		x = f32(x + f32(b*p1))
		x = f32(x + f32(c*p2))
		p2, p1, result = p1, x, x
	}
	if output == nil || cap < 1 do return -2
	output[0] = f64(result)
	return 1
}
