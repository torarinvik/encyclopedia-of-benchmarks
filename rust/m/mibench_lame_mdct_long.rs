const INPUT_COUNT: usize = 18;
const MAX_INPUT_LENGTH: usize = 19;
const OUTPUT_COUNT: usize = 18;
const PI: f64 = 3.14159265358979323846264338327950288;

#[no_mangle]
pub unsafe extern "C" fn mibench_lame_mdct_long(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|&v| !v.is_finite() || !(-16.0..=16.0).contains(&v)) { return -1; }
    if input_length != INPUT_COUNT { return -1; }

    let mut staged = [0.0_f64; OUTPUT_COUNT];
    for m in 0..OUTPUT_COUNT {
        let mut sum = 0.0;
        for k in 0..INPUT_COUNT {
            let offset = if k < 9 { 38 } else { 74 };
            let angle = PI * (2 * m + 1) as f64 * (4 * k + offset) as f64 / 144.0;
            sum += values[k] * angle.cos();
        }
        staged[m] = (4.0 / 36.0) * sum;
    }
    if output.is_null() || output_capacity < OUTPUT_COUNT { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_COUNT); }
    OUTPUT_COUNT as i64
}
