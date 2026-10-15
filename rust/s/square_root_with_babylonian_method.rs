#[no_mangle]
pub extern "C" fn square_root_with_babylonian_method(input: f64) -> f64 {
    if !(input >= 1.0 && input <= 1_000_000.0) {
        return -1.0;
    }
    let num = input as f32;
    let mut a = num;
    let mut b = 1.0_f32;
    let epsilon = 0.000001_f64;
    while (a - b) as f64 > epsilon {
        a = (a + b) / 2.0_f32;
        b = num / a;
    }
    a as f64
}
