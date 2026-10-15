module sum_of_geometric_progression

import math

// Sum a finite geometric progression using the pinned closed form.
@[export: 'sum_of_geometric_progression']
pub fn sum_of_geometric_progression(first_term f64, common_ratio f64, num_terms f64) f64 {
	if common_ratio == 1.0 {
		return num_terms * first_term
	}
	return (first_term / (1.0 - common_ratio)) * (1.0 - math.pow(common_ratio, num_terms))
}
