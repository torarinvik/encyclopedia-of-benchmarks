module conditional_probability;

// Return P(A | B) from P(A intersection B) and P(B).
fn double conditional_probability(double probability_intersection, double probability_b)
    @export("conditional_probability") {
    if (probability_intersection != probability_intersection || probability_b != probability_b ||
        probability_b <= 0.0 || probability_b > 1.0 ||
        probability_intersection < 0.0 || probability_intersection > probability_b) {
        return -1.0;
    }
    return probability_intersection / probability_b;
}
