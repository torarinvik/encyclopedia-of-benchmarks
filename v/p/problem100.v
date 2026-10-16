module problem100

@[export: 'problem100']
pub fn problem100(min_total i64) i64 {
	if min_total < 0 || min_total > 1_000_000_000_000 { return -1 }
	mut previous_numerator := i64(1)
	mut previous_denominator := i64(0)
	mut numerator := i64(1)
	mut denominator := i64(1)
	for numerator <= 2 * min_total - 1 {
		previous_numerator += 2 * numerator
		numerator += 2 * previous_numerator
		previous_denominator += 2 * denominator
		denominator += 2 * previous_denominator
	}
	return (denominator + 1) / 2
}
