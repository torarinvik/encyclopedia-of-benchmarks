// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
module rodinia_particlefilter_naive

import math

const scale = 1_000_000.0

fn round_away(value f64) i64 {
	scaled := value * 1000.0
	if scaled < 0 { return -i64(math.floor(-scaled + 0.5)) }
	return i64(math.floor(scaled + 0.5))
}

@[export: 'rodinia_particlefilter_naive']
pub fn rodinia_particlefilter_naive(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 8 || length > 35 { return -1 }
		n_raw, samples_raw, offset_raw := input[0], input[1], input[2]
		if n_raw < 1 || n_raw > 4 || samples_raw < 1 || samples_raw > 4 { return -1 }
		n, samples := int(n_raw), int(samples_raw)
		if length != usize(3 + n * (4 + samples)) || offset_raw < 0 || offset_raw >= 1_000_000 || offset_raw * n_raw >= 1_000_000 { return -1 }
		mut x, mut y, mut moved_x, mut moved_y := [4]f64{}, [4]f64{}, [4]f64{}, [4]f64{}
		mut weights, mut cdf, mut resampled_x, mut resampled_y := [4]f64{}, [4]f64{}, [4]f64{}, [4]f64{}
		for i in 0 .. n {
			at := 3 + i * (4 + samples)
			xr, yr, nxr, nyr := input[at], input[at + 1], input[at + 2], input[at + 3]
			if xr < -100_000_000 || xr > 100_000_000 || yr < -100_000_000 || yr > 100_000_000 || nxr < -2_000_000 || nxr > 2_000_000 || nyr < -2_000_000 || nyr > 2_000_000 { return -1 }
			x[i], y[i] = f64(xr) / scale, f64(yr) / scale
			moved_x[i] = x[i] + 1.0 + 5.0 * (f64(nxr) / scale)
			moved_y[i] = y[i] - 2.0 + 2.0 * (f64(nyr) / scale)
			mut likelihood_sum := 0.0
			for j in 0 .. samples {
				intensity := input[at + 4 + j]
				if intensity < 0 || intensity > 255 { return -1 }
				foreground, background := f64(intensity - 100), f64(intensity - 228)
				likelihood_sum += (foreground * foreground - background * background) / 50.0
			}
			likelihood := likelihood_sum / f64(samples)
			weights[i] = (1.0 / f64(n)) * math.exp(likelihood)
		}
		mut weight_sum := 0.0
		for i in 0 .. n { weight_sum += weights[i] }
		if !math.is_finite(weight_sum) || weight_sum <= 0.0 { return -1 }
		for i in 0 .. n { weights[i] /= weight_sum }
		mut estimate_x, mut estimate_y := 0.0, 0.0
		for i in 0 .. n { estimate_x += moved_x[i] * weights[i]; estimate_y += moved_y[i] * weights[i] }
		cdf[0] = weights[0]
		for i in 1 .. n { cdf[i] = weights[i] + cdf[i - 1] }
		offset := f64(offset_raw) / scale
		for i in 0 .. n {
			u := offset + f64(i) / f64(n)
			mut selected := n - 1
			for j in 0 .. n { if cdf[j] >= u { selected = j; break } }
			resampled_x[i], resampled_y[i] = moved_x[selected], moved_y[selected]
		}
		mut checksum := round_away(estimate_x) + 2 * round_away(estimate_y)
		for i in 0 .. n { checksum += i64(2 * i + 3) * round_away(resampled_x[i]) + i64(2 * i + 4) * round_away(resampled_y[i]) }
		return checksum
	}
}
