/// Return P(A | B) from P(A), P(B), and P(B | A).
#[no_mangle]
pub extern "C" fn bayes_theorem(probability_a: f64, probability_b: f64,
                                probability_b_given_a: f64) -> f64 {
    if !(0.0..=1.0).contains(&probability_a)
        || !(0.0..=1.0).contains(&probability_b_given_a)
        || !(0.0..=1.0).contains(&probability_b)
        || probability_b == 0.0
    {
        return -1.0;
    }
    let joint_probability = probability_a * probability_b_given_a;
    if joint_probability > probability_b {
        return -1.0;
    }
    joint_probability / probability_b
}
