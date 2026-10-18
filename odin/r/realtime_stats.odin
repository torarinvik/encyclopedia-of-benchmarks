package realtime_stats

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
MAX_INPUT_LENGTH :: 36
MAX_SAMPLES :: 32

@(export)
realtime_stats :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return INVALID_RESULT
	variant, statistic, count := values[0], values[1], values[2]
	if variant < 0 || variant > 2 || statistic < 0 || statistic > 2 || count < 2 || count > MAX_SAMPLES do return INVALID_RESULT
	if int(length) != 3 + int(count) do return INVALID_RESULT
	for i := 0; i < int(count); i += 1 { if values[3 + i] < -64 || values[3 + i] > 64 do return INVALID_RESULT }

	mean32: f32 = 0
	variance32: f32 = 0
	mean64: f64 = 0
	variance64: f64 = 0
	if variant == 0 {
		anchor: f32 = 0
		ex: f32 = 0
		ex2: f32 = 0
		n := 0
		for i := 0; i < int(count); i += 1 {
			x := f32(values[3 + i]) / 16.0
			if n == 0 { anchor = x }
			n += 1
			tmp := x - anchor
			ex += tmp
			ex2 += tmp * tmp
		}
		mean32 = anchor + ex / f32(n)
		variance32 = (ex2 - (ex * ex) / f32(n)) / f32(n - 1)
	} else if variant == 1 {
		mu: f32 = 0
		m: f32 = 0
		n := 0
		for i := 0; i < int(count); i += 1 {
			x := f32(values[3 + i]) / 16.0
			n += 1
			delta := x - mu
			mu += delta / f32(n)
			delta2 := x - mu
			m += delta * delta2
		}
		mean32 = mu
		variance32 = m / f32(n)
	} else {
		mu: f64 = 0
		m: f64 = 0
		n := 0
		for i := 0; i < int(count); i += 1 {
			x32 := f32(values[3 + i]) / 16.0
			x := f64(x32)
			n += 1
			delta := x - mu
			mu += delta / f64(n)
			delta2 := x - mu
			m += delta * delta2
		}
		mean64 = mu
		variance64 = m / f64(n)
	}

	if variant < 2 {
		if statistic == 0 do return f64(mean32)
		if statistic == 1 do return f64(variance32)
		return f64(f32(math.sqrt(f64(variance32))))
	}
	if statistic == 0 do return mean64
	if statistic == 1 do return variance64
	return math.sqrt(variance64)
}
