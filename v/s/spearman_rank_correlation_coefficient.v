module spearman_rank_correlation_coefficient

import math

const invalid_result = -1.0e300

fn assign_ranks(data &i64, offset int, n int, mut ranks &f64) {
	mut order := [3]int{}
	for i in 0 .. n { order[i] = i }
	for i in 1 .. n {
		key := order[i]
		mut j := i
		for j > 0 && unsafe { data[offset + order[j - 1]] } > unsafe { data[offset + key] } {
			order[j] = order[j - 1]
			j--
		}
		order[j] = key
	}
	mut i := 0
	for i < n {
		mut j := i
		for j < n - 1 && unsafe { data[offset + order[j + 1]] } == unsafe { data[offset + order[i]] } { j++ }
		rank := (f64(i) + f64(j)) / 2.0 + 1.0
		for k in i .. j + 1 { unsafe { ranks[order[k]] = rank } }
		i = j + 1
	}
}

fn round_tenth_ties_even(value f64) f64 {
	scaled := value * 10.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	mut rounded := lower
	if fraction > 0.5 || (fraction == 0.5 && i64(lower) % 2 != 0) { rounded = lower + 1.0 }
	return rounded / 10.0
}

@[export: 'spearman_rank_correlation_coefficient']
pub fn spearman_rank_correlation_coefficient(values &i64, length usize) f64 {
	if length < 5 { return invalid_result }
	n_value := unsafe { values[0] }
	if n_value < 2 || n_value > 3 || length != 1 + 2 * usize(n_value) { return invalid_result }
	n := int(n_value)
	for i in 0 .. n {
		xi := unsafe { values[1 + i] }
		yi := unsafe { values[1 + n + i] }
		if xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000 { return invalid_result }
	}
	mut rank_x := [3]f64{}
	mut rank_y := [3]f64{}
	assign_ranks(values, 1, n, &rank_x[0])
	assign_ranks(values, 1 + n, n, &rank_y[0])
	mut d_squared := 0.0
	for i in 0 .. n {
		difference := rank_x[i] - rank_y[i]
		d_squared += difference * difference
	}
	nf := f64(n)
	rho := 1.0 - (6.0 * d_squared) / (nf * (nf * nf - 1.0))
	return round_tenth_ties_even(rho)
}
