package cbench_rsynth_f0_flutter

import "core:c"
import "core:math"

@(export, link_name="cbench_rsynth_f0_flutter")
cbench_rsynth_f0_flutter :: proc "c" (input: [^]i64,n: c.size_t) -> i64 {
	if input == nil || n == 0 || n > 4 do return -1
	if n != 3 || input[0] < 0 || input[0] > 20_000 || input[1] < 0 || input[1] > 100 || input[2] < 0 || input[2] > 1_000_000 do return -1
	f0, flutter, t := input[0], input[1], input[2]
	original := f0 / 10
	pi :: 3.1415927
	fla := f64(flutter) / 50.0
	flb := f64(original) / 100.0
	flc := math.sin(2.0*pi*12.7*f64(t))
	fld := math.sin(2.0*pi*7.1*f64(t))
	fle := math.sin(2.0*pi*4.7*f64(t))
	delta := fla * flb * (flc + fld + fle) * 10.0
	return f0 + i64(delta)
}
