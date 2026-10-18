import math

const max_output = 38
const jacobi_tolerance = 1e-14
const min_eigen_gap = 1e-8

fn diagonalize(mut a [16]f64, mut vectors [16]f64, n int) ?[4]f64 {
	for i in 0 .. n {
		for j in 0 .. n { vectors[i * 4 + j] = if i == j { 1.0 } else { 0.0 } }
	}
	mut converged := false
	for sweep in 0 .. 65 {
		mut largest := 0.0
		for p in 0 .. n { for q in p + 1 .. n { largest = math.max(largest, math.abs(a[p * 4 + q])) } }
		if largest <= jacobi_tolerance { converged = true; break }
		if sweep == 64 { break }
		for p in 0 .. n {
			for q in p + 1 .. n {
				apq := a[p * 4 + q]
				if math.abs(apq) <= jacobi_tolerance { continue }
				tau := (a[q * 4 + q] - a[p * 4 + p]) / (2.0 * apq)
				sign := if tau >= 0 { 1.0 } else { -1.0 }
				t := sign / (math.abs(tau) + math.sqrt(1.0 + tau * tau))
				c := 1.0 / math.sqrt(1.0 + t * t)
				s := t * c
				app := a[p * 4 + p]; aqq := a[q * 4 + q]
				a[p * 4 + p] = app - t * apq; a[q * 4 + q] = aqq + t * apq
				a[p * 4 + q] = 0; a[q * 4 + p] = 0
				for r in 0 .. n {
					if r != p && r != q {
						arp := a[r * 4 + p]; arq := a[r * 4 + q]
						a[r * 4 + p] = c * arp - s * arq; a[p * 4 + r] = a[r * 4 + p]
						a[r * 4 + q] = s * arp + c * arq; a[q * 4 + r] = a[r * 4 + q]
					}
					vrp := vectors[r * 4 + p]; vrq := vectors[r * 4 + q]
					vectors[r * 4 + p] = c * vrp - s * vrq
					vectors[r * 4 + q] = s * vrp + c * vrq
				}
			}
		}
	}
	if !converged { return none }
	mut values := [4]f64{}
	for i in 0 .. n { values[i] = a[i * 4 + i] }
	for i in 0 .. n { for j in i + 1 .. n {
		if values[j] > values[i] {
			temp := values[i]; values[i] = values[j]; values[j] = temp
			for r in 0 .. n { temp_v := vectors[r * 4 + i]; vectors[r * 4 + i] = vectors[r * 4 + j]; vectors[r * 4 + j] = temp_v }
		}
	}}
	return values
}

@[export: 'principle_component_analysis']
pub fn principle_component_analysis(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 35 { return -1 }
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		for i in 0 .. 3 { if math.floor(input[i]) != input[i] { return -1 } }
		if input[0] < 3 || input[0] > 8 || input[1] < 2 || input[1] > 4 || input[2] < 1 || input[2] > 4 { return -1 }
		samples := int(input[0]); features := int(input[1]); components := int(input[2])
		if samples <= features || components > features || input_length != usize(3 + samples * features) { return -1 }
		mut rows := [32]f64{}; mut means := [4]f64{}
		for r in 0 .. samples { for c in 0 .. features {
			x := input[3 + r * features + c]
			if math.floor(x) != x || x < -9 || x > 9 { return -1 }
			rows[r * 4 + c] = x; means[c] += x
			if !means[c].is_finite() { return -1 }
		}}
		for c in 0 .. features { means[c] /= f64(samples) }
		mut variances := [4]f64{}
		for r in 0 .. samples { for c in 0 .. features { d := rows[r * 4 + c] - means[c]; variances[c] += d * d } }
		mut scales := [4]f64{}
		for c in 0 .. features {
			variances[c] /= f64(samples)
			if !(variances[c] > 0) || !variances[c].is_finite() { return -1 }
			scales[c] = math.sqrt(variances[c])
		}
		mut z := [32]f64{}; mut pca_means := [4]f64{}
		for r in 0 .. samples { for c in 0 .. features { z[r * 4 + c] = (rows[r * 4 + c] - means[c]) / scales[c]; pca_means[c] += z[r * 4 + c] } }
		for c in 0 .. features { pca_means[c] /= f64(samples) }
		mut centered := [32]f64{}
		for r in 0 .. samples { for c in 0 .. features { centered[r * 4 + c] = z[r * 4 + c] - pca_means[c] } }
		mut covariance := [16]f64{}
		for i in 0 .. features { for j in i .. features {
			mut sum := 0.0
			for r in 0 .. samples { sum += centered[r * 4 + i] * centered[r * 4 + j] }
			covariance[i * 4 + j] = sum / f64(samples - 1); covariance[j * 4 + i] = covariance[i * 4 + j]
			if !covariance[i * 4 + j].is_finite() { return -1 }
		}}
		mut vectors := [16]f64{}
		eigenvalues := diagonalize(mut covariance, mut vectors, features) or { return -1 }
		for i in 0 .. features { if !(eigenvalues[i] > 0) || !eigenvalues[i].is_finite() || (i + 1 < features && eigenvalues[i] - eigenvalues[i + 1] <= min_eigen_gap) { return -1 } }
		mut total := 0.0
		for i in 0 .. features { total += eigenvalues[i] }
		if !(total > 0) || !total.is_finite() { return -1 }
		mut scores := [32]f64{}
		for k in 0 .. components {
			for r in 0 .. samples { for c in 0 .. features { scores[k * 8 + r] += centered[r * 4 + c] * vectors[c * 4 + k] } }
			mut pivot := 0
			for r in 1 .. samples { if math.abs(scores[k * 8 + r]) > math.abs(scores[k * 8 + pivot]) { pivot = r } }
			if scores[k * 8 + pivot] < 0 { for r in 0 .. samples { scores[k * 8 + r] = -scores[k * 8 + r] } }
		}
		mut staged := [38]f64{}; staged[0] = f64(samples); staged[1] = f64(components)
		mut pos := 2
		for r in 0 .. samples { for k in 0 .. components { staged[pos] = scores[k * 8 + r]; pos++ } }
		for k in 0 .. components { staged[pos] = eigenvalues[k] / total; pos++ }
		for i in 0 .. pos { if !staged[i].is_finite() { return -1 } }
		if output == nil || capacity < usize(pos) { return -2 }
		for i in 0 .. pos { output[i] = staged[i] }
		return i64(pos)
	}
}
