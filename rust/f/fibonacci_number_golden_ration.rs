/// Binary64 Binet formula with Java Math.round semantics on the bounded domain.
#[no_mangle]
pub extern "C" fn fibonacci_number_golden_ration(input: i64) -> i64 {
    if !(0..=70).contains(&input) {
        return -1;
    }
    if input <= 1 {
        return input;
    }

    let sqrt5 = 5.0f64.sqrt();
    let phi = (1.0 + sqrt5) / 2.0;
    let psi = (1.0 - sqrt5) / 2.0;
    let result = (phi.powf(input as f64) - psi.powf(input as f64)) / sqrt5;
    (result + 0.5).floor() as i64
}
