module bayes_theorem;

// Return P(A | B) from P(A), P(B), and P(B | A).
fn double bayes_theorem(double probability_a, double probability_b,
                        double probability_b_given_a) @export("bayes_theorem") {
    if (probability_a < 0.0 || probability_a > 1.0 ||
        probability_b <= 0.0 || probability_b > 1.0 ||
        probability_b_given_a < 0.0 || probability_b_given_a > 1.0) {
        return -1.0;
    }
    double joint_probability = probability_a * probability_b_given_a;
    if (joint_probability > probability_b) return -1.0;
    return joint_probability / probability_b;
}
