const PI: f64 = 3.14159265358979323846264338327950288;
const ENWINDOW_MAX: f64 = 0.030526638;

#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_lame_mdct_short(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > 19 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|&v| !v.is_finite() || !(-32768.0..=32768.0).contains(&v)) || input_length != 18 { return -1; }

    let mut coefficients = [[0.0_f64; 6]; 6];
    let scale = 4.0 / 12.0;
    for i in 0..3 {
        let w2 = (PI / 12.0 * (i as f64 + 0.5)).cos() * ENWINDOW_MAX / 32768.0 * scale;
        for m in 0..6 {
            coefficients[m][i] = w2 * ((PI / 48.0) * (2 * m + 1) as f64 * (4 * i + 14) as f64).cos();
            coefficients[m][i + 3] = w2 * ((PI / 48.0) * (2 * m + 1) as f64 * (4 * i + 38) as f64).cos();
        }
    }
    let mut staged = [0.0_f64; 18];
    for m in (0..6).rev() {
        for l in (0..3).rev() {
            let base = 6 * l;
            let mut sum = coefficients[m][0] * values[base];
            for i in 1..6 { sum += coefficients[m][i] * values[base + i]; }
            staged[3 * m + l] = sum;
        }
    }
    if output.is_null() || output_capacity < 18 { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, 18); }
    18
}
