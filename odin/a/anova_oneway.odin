package anova_oneway

import "core:c"
import "core:math"

MAX_OBSERVATIONS :: 128
MAX_GROUPS :: 8
INVALID_RESULT :: f64(-1.0e300)

safe_denominator :: proc "contextless" (value: f64) -> f64 {
    magnitude := value
    if magnitude < 0.0 do magnitude = -magnitude
    if magnitude >= 1.0e-300 do return value
	if value < 0.0 do return -1.0e-300
	return 1.0e-300
}

log_gamma_lanczos :: proc "contextless" (value: f64) -> f64 {
	z := value - 1.0
	total := 0.99999999999980993
	total += 676.5203681218851 / (z + 1.0)
	total -= 1259.1392167224028 / (z + 2.0)
	total += 771.32342877765313 / (z + 3.0)
	total -= 176.61502916214059 / (z + 4.0)
	total += 12.507343278686905 / (z + 5.0)
	total -= 0.13857109526572012 / (z + 6.0)
	total += 9.9843695780195716e-6 / (z + 7.0)
	total += 1.5056327351493116e-7 / (z + 8.0)
	t := z + 7.5
	return 0.91893853320467274178 + (z + 0.5) * math.ln_f64(t) - t + math.ln_f64(total)
}

beta_fraction :: proc "contextless" (a, b, x: f64) -> f64 {
	qab := a + b
	qap := a + 1.0
	qam := a - 1.0
	c := 1.0
	d := safe_denominator(1.0 - qab * x / qap)
	d = 1.0 / d
	result := d
	for m := 1; m <= 200; m += 1 {
		md := f64(m)
		m2 := 2.0 * md
		coefficient := md * (b - md) * x / ((qam + m2) * (a + m2))
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
		difference := change - 1.0
		if difference < 0.0 do difference = -difference
		if difference <= 3.0e-14 do break
	}
	return result
}

regularized_beta :: proc "contextless" (x, a, b: f64) -> f64 {
	if x <= 0.0 do return 0.0
	if x >= 1.0 do return 1.0
	front := math.exp_f64(a*math.ln_f64(x) + b*math.ln_f64(1.0-x) +
		log_gamma_lanczos(a+b) - log_gamma_lanczos(a) - log_gamma_lanczos(b))
	if x < (a+1.0)/(a+b+2.0) do return front * beta_fraction(a, b, x) / a
	return 1.0 - front * beta_fraction(b, a, 1.0-x) / b
}

@(export)
anova_oneway :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 do return INVALID_RESULT
	statistic := input[0]
	observation_count := input[1]
	group_count := input[2]
	if statistic < 0 || statistic > 7 || observation_count <= group_count || observation_count > MAX_OBSERVATIONS || group_count < 2 || group_count > MAX_GROUPS || length != 3 + 2*c.size_t(observation_count) do return INVALID_RESULT

	group_sums: [MAX_GROUPS]f64
	group_means: [MAX_GROUPS]f64
	group_sizes: [MAX_GROUPS]i64
	labels: [MAX_OBSERVATIONS]i64
	for group := 0; group < MAX_GROUPS; group += 1 { group_sums[group] = 0.0; group_means[group] = 0.0; group_sizes[group] = 0 }
	total := 0.0
	for i := 0; i < int(observation_count); i += 1 {
		value := input[3+i]
		group := input[3+int(observation_count)+i]
		if value < -1_000_000 || value > 1_000_000 || group < 0 || group >= group_count do return INVALID_RESULT
		labels[i] = group
		group_sums[int(group)] += f64(value)
		group_sizes[int(group)] += 1
		total += f64(value)
	}
	for group := 0; group < int(group_count); group += 1 {
		if group_sizes[group] == 0 do return INVALID_RESULT
		group_means[group] = group_sums[group] / f64(group_sizes[group])
	}
	grand_mean := total / f64(observation_count)
	ss_between := 0.0
	for group := 0; group < int(group_count); group += 1 {
		difference := group_means[group] - grand_mean
		ss_between += f64(group_sizes[group]) * difference * difference
	}
	ss_within := 0.0
	for group := 0; group < int(group_count); group += 1 {
		for i := 0; i < int(observation_count); i += 1 {
			if labels[i] == i64(group) {
				difference := f64(input[3+i]) - group_means[group]
				ss_within += difference * difference
			}
		}
	}
	if ss_within <= 0.0 do return INVALID_RESULT
	df_between := f64(group_count - 1)
	df_within := f64(observation_count - group_count)
	ms_between := ss_between / df_between
	ms_within := ss_within / df_within
	f_statistic := ms_between / ms_within
	beta_x := df_within / (df_within + df_between * f_statistic)
	p_value := regularized_beta(beta_x, df_within/2.0, df_between/2.0)
	outputs: [8]f64
	outputs[0] = df_between; outputs[1] = df_within; outputs[2] = ss_between; outputs[3] = ss_within
	outputs[4] = ms_between; outputs[5] = ms_within; outputs[6] = f_statistic; outputs[7] = p_value
	return outputs[int(statistic)]
}
