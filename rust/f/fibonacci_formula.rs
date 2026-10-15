/// Source-ordered Binet formula, rounded to f32 then truncated to i32.
#[no_mangle]
pub extern "C" fn fibonacci_formula(input: i64) -> i64 {
    if !(0..=35).contains(&input) {
        return -1;
    }
    let n = input as u32;
    let exponent = (n + 1) as f64;
    let seq = (1.0 / 5.0f64.sqrt() * ((1.0 + 5.0f64.sqrt()) / 2.0).powf(exponent)
        - 1.0 / 5.0f64.sqrt() * ((1.0 - 5.0f64.sqrt()) / 2.0).powf(exponent)) as f32;
    seq as i32 as i64
}
