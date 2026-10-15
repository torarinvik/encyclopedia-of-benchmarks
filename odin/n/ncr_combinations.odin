package ncr_combinations

INVALID_RESULT :: -1.0e300

@(export)
ncr_combinations :: proc "c" (total, choose: f64) -> f64 {
	if total != total || choose != choose || total < 0.0 || total > 20.0 ||
		choose < 0.0 || choose > 12.0 || choose != f64(i64(choose)) do return INVALID_RESULT

	count := i64(choose)
	numerator := f64(1.0)
	for index := i64(0); index < count; index += 1 {
		numerator *= total - f64(index)
	}
	denominator := f64(1.0)
	for factor := i64(2); factor <= count; factor += 1 {
		denominator *= f64(factor)
	}
	return numerator / denominator
}
