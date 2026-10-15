module ncr_combinations

const invalid_result = -1.0e300

@[export: 'ncr_combinations']
pub fn ncr_combinations(total f64, choose f64) f64 {
	if total != total || choose != choose || total < 0.0 || total > 20.0 ||
		choose < 0.0 || choose > 12.0 || choose != f64(i64(choose)) { return invalid_result }
	count := i64(choose)
	mut numerator := f64(1.0)
	for index in 0 .. int(count) {
		numerator *= total - f64(index)
	}
	mut denominator := f64(1.0)
	for factor in 2 .. int(count + 1) {
		denominator *= f64(factor)
	}
	return numerator / denominator
}
