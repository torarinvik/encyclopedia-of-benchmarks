#[no_mangle]
pub extern "C" fn pi_nilakantha(input: f64) -> f64 {
    if !(input >= 0.0 && input <= 500.0 && input == (input as i32) as f64) {
        return -1.0;
    }
    let iterations = input as i32;
    let mut pi = 3.0_f64;
    let mut div_counter = 2_i32;
    for i in 0..iterations {
        let term = 4.0 / (div_counter * (div_counter + 1) * (div_counter + 2)) as f64;
        if i % 2 == 0 { pi = pi + term; }
        else { pi = pi - term; }
        div_counter += 2;
    }
    pi
}
