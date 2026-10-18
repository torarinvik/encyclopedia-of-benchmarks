package principle_component_analysis

import "core:c"
import "core:math"

JACOBI_TOLERANCE :: 1e-14
MIN_EIGEN_GAP :: 1e-8
MAX_OUTPUT :: 38

diagonalize :: proc(a: ^[16]f64, vectors: ^[16]f64, n: int) -> ([4]f64, bool) {
	for i in 0..<n {
		for j in 0..<n { vectors[i*4+j] = 0; if i == j { vectors[i*4+j] = 1 } }
	}
	converged := false
	for sweep in 0..<65 {
		largest: f64 = 0
		for p in 0..<n { for q in p+1..<n { largest = math.max(largest, math.abs(a[p*4+q])) } }
		if largest <= JACOBI_TOLERANCE { converged = true; break }
		if sweep == 64 { break }
		for p in 0..<n {
			for q in p+1..<n {
				apq := a[p*4+q]
				if math.abs(apq) <= JACOBI_TOLERANCE { continue }
				tau := (a[q*4+q]-a[p*4+p])/(2*apq)
				sign: f64 = 1; if tau < 0 { sign = -1 }
				t := sign/(math.abs(tau)+math.sqrt(1+tau*tau))
				c := 1/math.sqrt(1+t*t); s := t*c
				app := a[p*4+p]; aqq := a[q*4+q]
				a[p*4+p] = app-t*apq; a[q*4+q] = aqq+t*apq
				a[p*4+q] = 0; a[q*4+p] = 0
				for r in 0..<n {
					if r != p && r != q {
						arp := a[r*4+p]; arq := a[r*4+q]
						a[r*4+p] = c*arp-s*arq; a[p*4+r] = a[r*4+p]
						a[r*4+q] = s*arp+c*arq; a[q*4+r] = a[r*4+q]
					}
					vrp := vectors[r*4+p]; vrq := vectors[r*4+q]
					vectors[r*4+p] = c*vrp-s*vrq; vectors[r*4+q] = s*vrp+c*vrq
				}
			}
		}
	}
	if !converged { return {}, false }
	values: [4]f64
	for i in 0..<n { values[i] = a[i*4+i] }
	for i in 0..<n { for j in i+1..<n {
		if values[j] > values[i] {
			tmp := values[i]; values[i] = values[j]; values[j] = tmp
			for r in 0..<n { tmpv := vectors[r*4+i]; vectors[r*4+i] = vectors[r*4+j]; vectors[r*4+j] = tmpv }
		}
	}}
	return values, true
}

@(export)
principle_component_analysis :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > 35 do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	for i in 0..<3 { if math.trunc(input[i]) != input[i] do return -1 }
	if input[0] < 3 || input[0] > 8 || input[1] < 2 || input[1] > 4 || input[2] < 1 || input[2] > 4 do return -1
	samples, features, components := int(input[0]), int(input[1]), int(input[2])
	if samples <= features || components > features || input_length != c.size_t(3+samples*features) do return -1
	rows: [32]f64
	means: [4]f64
	for r in 0..<samples { for col in 0..<features {
		x := input[3+r*features+col]
		if math.trunc(x) != x || x < -9 || x > 9 do return -1
		rows[r*4+col] = x; means[col] += x
		if !math.is_finite(means[col]) do return -1
	}}
	for col in 0..<features { means[col] /= f64(samples) }
	variances: [4]f64
	for r in 0..<samples { for col in 0..<features { d := rows[r*4+col]-means[col]; variances[col] += d*d } }
	scales: [4]f64
	for col in 0..<features {
		variances[col] /= f64(samples)
		if !(variances[col] > 0) || !math.is_finite(variances[col]) do return -1
		scales[col] = math.sqrt(variances[col])
	}
	z: [32]f64
	pca_means: [4]f64
	for r in 0..<samples { for col in 0..<features { z[r*4+col] = (rows[r*4+col]-means[col])/scales[col]; pca_means[col] += z[r*4+col] } }
	for col in 0..<features { pca_means[col] /= f64(samples) }
	centered: [32]f64
	for r in 0..<samples { for col in 0..<features { centered[r*4+col] = z[r*4+col]-pca_means[col] } }
	covariance: [16]f64
	for i in 0..<features { for j in i..<features {
		sum: f64 = 0
		for r in 0..<samples { sum += centered[r*4+i]*centered[r*4+j] }
		covariance[i*4+j] = sum/f64(samples-1); covariance[j*4+i] = covariance[i*4+j]
	}}
	vectors: [16]f64
	eigenvalues, ok := diagonalize(&covariance, &vectors, features)
	if !ok do return -1
	for i in 0..<features { if !(eigenvalues[i] > 0) || !math.is_finite(eigenvalues[i]) || (i+1<features && eigenvalues[i]-eigenvalues[i+1] <= MIN_EIGEN_GAP) do return -1 }
	total: f64 = 0
	for i in 0..<features { total += eigenvalues[i] }
	if !(total > 0) || !math.is_finite(total) do return -1
	scores: [32]f64
	for k in 0..<components {
		for r in 0..<samples { for col in 0..<features { scores[k*8+r] += centered[r*4+col]*vectors[col*4+k] } }
		pivot := 0
		for r in 1..<samples { if math.abs(scores[k*8+r]) > math.abs(scores[k*8+pivot]) { pivot = r } }
		if scores[k*8+pivot] < 0 { for r in 0..<samples { scores[k*8+r] = -scores[k*8+r] } }
	}
	staged: [MAX_OUTPUT]f64
	staged[0], staged[1] = f64(samples), f64(components)
	pos := 2
	for r in 0..<samples { for k in 0..<components { staged[pos] = scores[k*8+r]; pos += 1 } }
	for k in 0..<components { staged[pos] = eigenvalues[k]/total; pos += 1 }
	for i in 0..<pos { if !math.is_finite(staged[i]) do return -1 }
	if output == nil || capacity < c.size_t(pos) do return -2
	for i in 0..<pos { output[i] = staged[i] }
	return i64(pos)
}
