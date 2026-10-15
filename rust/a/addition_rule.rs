/// Probability of A or B using the conditional probability P(B | A).
#[no_mangle]
pub extern "C" fn addition_rule(probability_a: f64, probability_b: f64,
                                probability_b_given_a: f64) -> f64 {
    (probability_a + probability_b) - (probability_a * probability_b_given_a)
}
