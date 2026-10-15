const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn nth_root(radicand: f64, index: f64, tolerance: f64) -> f64 {
    if !radicand.is_finite() || !index.is_finite() || !tolerance.is_finite() ||
        radicand < 0.5 || radicand > 1000.0 || index < 3.0 || index > 8.0 ||
        index.fract() != 0.0 || tolerance < 1.0e-12 || tolerance > 1.0e-3
    {
        return INVALID_RESULT;
    }
    let mut new_approximation = radicand;
    let mut old_approximation = new_approximation + tolerance + 0.1;
    while tolerance <= (old_approximation - new_approximation).abs() {
        old_approximation = new_approximation;
        let first_summand = (index - 1.0) / index * old_approximation;
        let second_summand = radicand / (index * old_approximation.powf(index - 1.0));
        new_approximation = first_summand + second_summand;
    }
    new_approximation
}
