module problem493

fn choose_ten(n i64) i64 {
	mut result := i64(1)
	for i in 0 .. 10 { result = result * (n - i64(i)) / (i64(i) + 1) }
	return result
}

@[export: 'problem493']
pub fn problem493(picks i64) i64 {
	if picks < 0 || picks > 70 { return -1 }
	denominator := choose_ten(70)
	mut missing := i64(0)
	if picks <= 60 { missing = choose_ten(70 - picks) }
	numerator := 7 * (denominator - missing)
	whole := numerator / denominator
	mut remainder := numerator % denominator
	mut fraction := i64(0)
	for _ in 0 .. 9 { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator }
	remainder *= 10
	guard := remainder / denominator
	remainder %= denominator
	mut scaled := whole * 1_000_000_000 + fraction
	if guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0)) { scaled++ }
	return scaled
}
