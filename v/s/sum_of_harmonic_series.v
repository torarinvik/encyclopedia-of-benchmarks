module sum_of_harmonic_series
import math
const invalid_result = -1.0e300
@[export: 'sum_of_harmonic_series']
pub fn sum_of_harmonic_series(first_term f64, common_difference f64, number_of_terms f64) f64 {
    if !first_term.is_finite() || !common_difference.is_finite() || !number_of_terms.is_finite() ||
        first_term <= 0.0 || first_term > 1000.0 || common_difference < 0.0 || common_difference > 1000.0 ||
        number_of_terms < 1.0 || number_of_terms > 256.0 || math.floor(number_of_terms) != number_of_terms { return invalid_result }
    count := int(number_of_terms)
    mut arithmetic_term := 1.0 / first_term
    mut total := 0.0
    for index in 0 .. count {
        total += 1.0 / arithmetic_term
        if index + 1 < count { arithmetic_term += common_difference }
    }
    return total
}
