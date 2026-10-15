package bayes_theorem

// Return P(A | B) from P(A), P(B), and P(B | A).
@(export)
bayes_theorem :: proc "c" (probability_a, probability_b,
                            probability_b_given_a: f64) -> f64 {
    if probability_a < 0.0 || probability_a > 1.0 ||
       probability_b <= 0.0 || probability_b > 1.0 ||
       probability_b_given_a < 0.0 || probability_b_given_a > 1.0 {
        return -1.0
    }
    joint_probability := probability_a * probability_b_given_a
    if joint_probability > probability_b do return -1.0
    return joint_probability / probability_b
}
