package addition_rule

// Probability of A or B using P(B | A). Set P(B | A) = P(B) for independence.
@(export)
addition_rule :: proc "c" (probability_a, probability_b, probability_b_given_a: f64) -> f64 {
	return (probability_a + probability_b) - (probability_a * probability_b_given_a)
}
