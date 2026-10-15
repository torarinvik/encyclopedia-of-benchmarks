module addition_rule

// Probability of A or B using P(B | A). Set P(B | A) = P(B) for independence.
@[export: 'addition_rule']
pub fn addition_rule(probability_a f64, probability_b f64, probability_b_given_a f64) f64 {
	return (probability_a + probability_b) - (probability_a * probability_b_given_a)
}
