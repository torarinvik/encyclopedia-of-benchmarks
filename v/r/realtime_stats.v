module realtime_stats

import math

const invalid_result = -1.0e300
const max_input_length = 36
const max_samples = 32

@[export: 'realtime_stats']
pub fn realtime_stats(values &i64, length usize) f64 {
	unsafe {
		if values == nil || length < 3 || length > usize(max_input_length) { return invalid_result }
		variant, statistic, count := values[0], values[1], values[2]
		if variant < 0 || variant > 2 || statistic < 0 || statistic > 2 || count < 2 || count > max_samples { return invalid_result }
		if int(length) != 3 + int(count) { return invalid_result }
		for i in 0 .. int(count) { if values[3 + i] < -64 || values[3 + i] > 64 { return invalid_result } }

		mut mean32 := f32(0)
		mut variance32 := f32(0)
		mut mean64 := f64(0)
		mut variance64 := f64(0)
		if variant == 0 {
			mut anchor := f32(0)
			mut ex := f32(0)
			mut ex2 := f32(0)
			mut n := 0
			for i in 0 .. int(count) {
				x := f32(values[3 + i]) / f32(16)
				if n == 0 { anchor = x }
				n++
				tmp := x - anchor
				ex += tmp
				ex2 += tmp * tmp
			}
			mean32 = anchor + ex / f32(n)
			variance32 = (ex2 - (ex * ex) / f32(n)) / f32(n - 1)
		} else if variant == 1 {
			mut mu := f32(0)
			mut m := f32(0)
			mut n := 0
			for i in 0 .. int(count) {
				x := f32(values[3 + i]) / f32(16)
				n++
				delta := x - mu
				mu += delta / f32(n)
				delta2 := x - mu
				m += delta * delta2
			}
			mean32 = mu
			variance32 = m / f32(n)
		} else {
			mut mu := f64(0)
			mut m := f64(0)
			mut n := 0
			for i in 0 .. int(count) {
				x32 := f32(values[3 + i]) / f32(16)
				x := f64(x32)
				n++
				delta := x - mu
				mu += delta / f64(n)
				delta2 := x - mu
				m += delta * delta2
			}
			mean64 = mu
			variance64 = m / f64(n)
		}

		if variant < 2 {
			if statistic == 0 { return f64(mean32) }
			if statistic == 1 { return f64(variance32) }
			return f64(f32(math.sqrt(f64(variance32))))
		}
		if statistic == 0 { return mean64 }
		if statistic == 1 { return variance64 }
		return math.sqrt(variance64)
	}
}
