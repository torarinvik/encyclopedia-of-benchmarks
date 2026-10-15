module anova_oneway

import math

const max_observations = 128
const max_groups = 8
const invalid_result = -1.0e300

fn safe_denominator(value f64) f64 {
	if math.abs(value) >= 1.0e-300 { return value }
	if value < 0.0 { return -1.0e-300 }
	return 1.0e-300
}

fn log_gamma_lanczos(value f64) f64 {
	z := value - 1.0
	mut total := 0.99999999999980993
	total += 676.5203681218851 / (z + 1.0)
	total -= 1259.1392167224028 / (z + 2.0)
	total += 771.32342877765313 / (z + 3.0)
	total -= 176.61502916214059 / (z + 4.0)
	total += 12.507343278686905 / (z + 5.0)
	total -= 0.13857109526572012 / (z + 6.0)
	total += 9.9843695780195716e-6 / (z + 7.0)
	total += 1.5056327351493116e-7 / (z + 8.0)
	t := z + 7.5
	return 0.91893853320467274178 + (z + 0.5) * math.log(t) - t + math.log(total)
}

fn beta_fraction(a f64, b f64, x f64) f64 {
	qab := a + b
	qap := a + 1.0
	qam := a - 1.0
	mut c := 1.0
	mut d := safe_denominator(1.0 - qab * x / qap)
	d = 1.0 / d
	mut result := d
	for m in 1 .. 201 {
		md := f64(m)
		m2 := 2.0 * md
		mut coefficient := md * (b - md) * x / ((qam + m2) * (a + m2))
		d = safe_denominator(1.0 + coefficient * d)
		c = safe_denominator(1.0 + coefficient / c)
		d = 1.0 / d
		result *= d * c
		coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2))
		d = safe_denominator(1.0 + coefficient * d)
		c = safe_denominator(1.0 + coefficient / c)
		d = 1.0 / d
		change := d * c
		result *= change
		if math.abs(change - 1.0) <= 3.0e-14 { break }
	}
	return result
}

fn regularized_beta(x f64, a f64, b f64) f64 {
	if x <= 0.0 { return 0.0 }
	if x >= 1.0 { return 1.0 }
	front := math.exp(a * math.log(x) + b * math.log(1.0 - x) +
		log_gamma_lanczos(a + b) - log_gamma_lanczos(a) - log_gamma_lanczos(b))
	if x < (a + 1.0) / (a + b + 2.0) { return front * beta_fraction(a, b, x) / a }
	return 1.0 - front * beta_fraction(b, a, 1.0 - x) / b
}

@[export: 'anova_oneway']
pub fn anova_oneway(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 3 { return invalid_result }
	unsafe {
		statistic := input[0]
		observation_count := input[1]
		group_count := input[2]
		if statistic < 0 || statistic > 7 || observation_count <= group_count || observation_count > max_observations || group_count < 2 || group_count > max_groups || length != 3 + 2 * usize(observation_count) { return invalid_result }

		mut group_sums := [max_groups]f64{}
		mut group_means := [max_groups]f64{}
		mut group_sizes := [max_groups]int{}
		mut labels := [max_observations]int{}
		mut total := 0.0
		for i in 0 .. int(observation_count) {
			value := input[3 + i]
			group := input[3 + int(observation_count) + i]
			if value < -1_000_000 || value > 1_000_000 || group < 0 || group >= group_count { return invalid_result }
			labels[i] = int(group)
			group_sums[int(group)] += f64(value)
			group_sizes[int(group)]++
			total += f64(value)
		}
		for group in 0 .. int(group_count) {
			if group_sizes[group] == 0 { return invalid_result }
			group_means[group] = group_sums[group] / f64(group_sizes[group])
		}
		grand_mean := total / f64(observation_count)
		mut ss_between := 0.0
		for group in 0 .. int(group_count) {
			difference := group_means[group] - grand_mean
			ss_between += f64(group_sizes[group]) * difference * difference
		}
		mut ss_within := 0.0
		for group in 0 .. int(group_count) {
			for i in 0 .. int(observation_count) {
				if labels[i] == group {
					difference := f64(input[3 + i]) - group_means[group]
					ss_within += difference * difference
				}
			}
		}
		if ss_within <= 0.0 { return invalid_result }
		df_between := f64(group_count - 1)
		df_within := f64(observation_count - group_count)
		ms_between := ss_between / df_between
		ms_within := ss_within / df_within
		f_statistic := ms_between / ms_within
		beta_x := df_within / (df_within + df_between * f_statistic)
		p_value := regularized_beta(beta_x, df_within / 2.0, df_between / 2.0)
		outputs := [df_between, df_within, ss_between, ss_within, ms_between, ms_within, f_statistic, p_value]
		return outputs[int(statistic)]
	}
}
