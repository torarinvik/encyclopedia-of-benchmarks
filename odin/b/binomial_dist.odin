package binomial_dist

import "core:math"

// Probability of exactly x successes in n Bernoulli trials.
@(export)
binomial_dist :: proc "c" (n, p, x: f64) -> f64 {
	n_integer := i32(n)
	x_integer := i32(x)
	numerator := n
	denominator := x
	for i := n_integer - 1; i >= n_integer - x_integer + 1; i -= 1 {
		numerator *= f64(i)
	}
	for i := 1; i < x_integer; i += 1 {
		denominator *= f64(i)
	}
	return (numerator / denominator) * math.pow(p, x) * math.pow(1.0 - p, n - x)
}
