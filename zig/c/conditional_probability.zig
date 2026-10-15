/// Return P(A | B) from P(A intersection B) and P(B).
export fn conditional_probability(probability_intersection: f64, probability_b: f64) f64 {
    if (probability_intersection != probability_intersection or probability_b != probability_b or
        probability_b <= 0.0 or probability_b > 1.0 or
        probability_intersection < 0.0 or probability_intersection > probability_b) return -1.0;
    return probability_intersection / probability_b;
}
