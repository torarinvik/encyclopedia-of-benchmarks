module mirror_formulae

fn valid_distance(value f64) bool {
	return (value >= -1.0e6 && value <= -1.0e-6) || (value >= 1.0e-6 && value <= 1.0e6)
}

// The source module exposes three mirror-equation rearrangements.
@[export: 'mirror_formulae']
pub fn mirror_formulae(distance_a f64, distance_b f64, operation_code f64) f64 {
	invalid := -1.0e300
	if !valid_distance(distance_a) || !valid_distance(distance_b)
		|| !(operation_code == 0.0 || operation_code == 1.0 || operation_code == 2.0) {
		return invalid
	}

	denominator := if operation_code == 0.0 {
		(1.0 / distance_a) + (1.0 / distance_b)
	} else {
		(1.0 / distance_a) - (1.0 / distance_b)
	}
	if denominator == 0.0 {
		return invalid
	}
	return 1.0 / denominator
}
