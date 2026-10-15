/// Return P(A | B) from P(A intersection B) and P(B).
#[no_mangle]
pub extern "C" fn conditional_probability(probability_intersection: f64, probability_b: f64) -> f64 {
    if !(0.0..=1.0).contains(&probability_b) || probability_b == 0.0
        || !(0.0..=probability_b).contains(&probability_intersection)
    {
        return -1.0;
    }
    probability_intersection / probability_b
}
