module addition_rule;

// Probability of A or B using P(B | A). Set P(B | A) = P(B) for independence.
fn double addition_rule(double probability_a, double probability_b,
                        double probability_b_given_a) @export("addition_rule") {
    return (probability_a + probability_b) - (probability_a * probability_b_given_a);
}
