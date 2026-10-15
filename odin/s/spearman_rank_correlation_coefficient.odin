package spearman_rank_correlation_coefficient

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

assign_ranks :: proc(data: [^]i64, offset, n: int, ranks: [^]f64) {
	order: [3]int
	for i in 0..<n do order[i] = i
	for i in 1..<n {
		key := order[i]
	j := i
		for j > 0 && data[offset+order[j-1]] > data[offset+key] {
			order[j] = order[j-1]
			j -= 1
		}
		order[j] = key
	}
	i := 0
	for i < n {
		j := i
		for j < n-1 && data[offset+order[j+1]] == data[offset+order[i]] do j += 1
		rank := (f64(i) + f64(j))/2.0 + 1.0
		for k in i..=j do ranks[order[k]] = rank
		i = j + 1
	}
}

round_tenth_ties_even :: proc(value: f64) -> f64 {
	scaled := value * 10.0
	lower := math.floor_f64(scaled)
	fraction := scaled - lower
	rounded := lower
	if fraction > 0.5 || (fraction == 0.5 && i64(lower)%2 != 0) do rounded = lower + 1.0
	return rounded / 10.0
}

@(export)
spearman_rank_correlation_coefficient :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 do return INVALID_RESULT
	n_value := values[0]
	if n_value < 2 || n_value > 3 || length != 1 + 2*c.size_t(n_value) do return INVALID_RESULT
	n := int(n_value)
	for i in 0..<n {
		if values[1+i] < -1000 || values[1+i] > 1000 || values[1+n+i] < -1000 || values[1+n+i] > 1000 do return INVALID_RESULT
	}
	rank_x, rank_y: [3]f64
	assign_ranks(values, 1, n, &rank_x[0])
	assign_ranks(values, 1+n, n, &rank_y[0])
	d_squared: f64 = 0.0
	for i in 0..<n {
		difference := rank_x[i] - rank_y[i]
		d_squared += difference * difference
	}
	nf := f64(n)
	rho := 1.0 - (6.0*d_squared)/(nf*(nf*nf-1.0))
	return round_tenth_ties_even(rho)
}
