package sum_of_geometric_progression

import "core:math"

// Sum a finite geometric progression using the pinned closed form.
@(export)
sum_of_geometric_progression :: proc "c" (first_term, common_ratio, num_terms: f64) -> f64 {
	if common_ratio == 1.0 {
		return num_terms * first_term
	}
	return (first_term / (1.0 - common_ratio)) * (1.0 - math.pow_f64(common_ratio, num_terms))
}
