package sum_of_harmonic_series
import "core:c"
import "core:math"
INVALID_RESULT :: f64(-1.0e300)
@(export)
sum_of_harmonic_series :: proc "c" (first_term, common_difference, number_of_terms: f64) -> f64 {
    if math.is_nan_f64(first_term) || math.is_nan_f64(common_difference) || math.is_nan_f64(number_of_terms) ||
        first_term <= 0.0 || first_term > 1000.0 || common_difference < 0.0 || common_difference > 1000.0 ||
        number_of_terms < 1.0 || number_of_terms > 256.0 || math.floor_f64(number_of_terms) != number_of_terms {
        return INVALID_RESULT
    }
    count := i32(number_of_terms)
    arithmetic_term := 1.0 / first_term
    total := f64(0.0)
    for index := i32(0); index < count; index += 1 {
        total += 1.0 / arithmetic_term
        if index + 1 < count do arithmetic_term += common_difference
    }
    return total
}
