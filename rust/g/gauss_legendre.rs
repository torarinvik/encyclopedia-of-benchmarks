const MAX_ITERATIONS: i32 = 8;
const INVALID_RESULT: f64 = -1.0e300;

fn pi_after_iterations(iterations: i32) -> f64 {
    let mut a = 1.0_f64;
    let mut b = 0.5_f64.sqrt();
    let mut t = 0.25_f64;
    let mut p = 1.0_f64;
    for _ in 0..iterations {
        let next_a = (a + b) / 2.0;
        let next_b = (a * b).sqrt();
        let difference = a - next_a;
        let next_t = t - p * difference * difference;
        let next_p = 2.0 * p;
        a = next_a;
        b = next_b;
        t = next_t;
        p = next_p;
    }
    let sum = a + b;
    sum * sum / (4.0 * t)
}

#[no_mangle]
pub extern "C" fn gauss_legendre(iterations_value: f64) -> f64 {
    if !(iterations_value >= 0.0 && iterations_value <= MAX_ITERATIONS as f64)
        || iterations_value.fract() != 0.0 { return INVALID_RESULT; }
    pi_after_iterations(iterations_value as i32)
}
