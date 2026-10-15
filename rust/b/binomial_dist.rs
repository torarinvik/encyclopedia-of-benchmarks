/// Probability of exactly x successes in n Bernoulli trials.
#[no_mangle]
pub extern "C" fn binomial_dist(n: f64, p: f64, x: f64) -> f64 {
    let n_integer = n as i32;
    let x_integer = x as i32;
    let mut numerator = n;
    let mut denominator = x;
    let mut i = n_integer - 1;
    while i >= n_integer - x_integer + 1 {
        numerator *= f64::from(i);
        i -= 1;
    }
    i = 1;
    while i < x_integer {
        denominator *= f64::from(i);
        i += 1;
    }
    (numerator / denominator) * p.powi(x_integer) * (1.0 - p).powi(n_integer - x_integer)
}
