module binomial_dist

import math

// Probability of exactly x successes in n Bernoulli trials.
@[export: 'binomial_dist']
pub fn binomial_dist(n f64, p f64, x f64) f64 {
	n_integer := int(n)
	x_integer := int(x)
	mut numerator := n
	mut denominator := x
	mut i := n_integer - 1
	for i >= n_integer - x_integer + 1 {
		numerator *= f64(i)
		i--
	}
	i = 1
	for i < x_integer {
		denominator *= f64(i)
		i++
	}
	return (numerator / denominator) * math.pow(p, x) * math.pow(1.0 - p, n - x)
}
