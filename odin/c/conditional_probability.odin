package conditional_probability

// Return P(A | B) from P(A intersection B) and P(B).
@(export)
conditional_probability :: proc "c" (probability_intersection, probability_b: f64) -> f64 {
    if probability_intersection != probability_intersection || probability_b != probability_b ||
       probability_b <= 0.0 || probability_b > 1.0 ||
       probability_intersection < 0.0 || probability_intersection > probability_b {
        return -1.0
    }
    return probability_intersection / probability_b
}
