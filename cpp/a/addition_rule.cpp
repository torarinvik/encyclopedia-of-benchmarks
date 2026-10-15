// Probability of A or B using the conditional probability P(B | A).
extern "C" double addition_rule(double probability_a, double probability_b,
                                double probability_b_given_a) noexcept {
    return (probability_a + probability_b) - (probability_a * probability_b_given_a);
}
