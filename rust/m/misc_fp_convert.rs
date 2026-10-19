const MAX_ITERATIONS: i64 = 256;
const VECTOR_LENGTH: usize = 2048;

#[no_mangle]
pub unsafe extern "C" fn misc_fp_convert(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 1 { return -1; }
    let requested = unsafe { *input };
    if !(requested >= 1.0 && requested <= MAX_ITERATIONS as f64) || requested.fract() != 0.0 {
        return -1;
    }
    if output.is_null() || output_capacity < 1 { return -2; }

    let iterations = requested as i64;
    let mut x = [0.0_f32; VECTOR_LENGTH];
    let mut y = [0.0_f32; VECTOR_LENGTH];
    let mut a = 0.0_f32;
    let mut b = 1.0_f32;
    let mut total = 0.0_f64;
    for iteration in 0..iterations {
        if iteration % 10 != 0 {
            a = 0.0;
            b = 1.0;
        } else {
            a += 0.1_f32;
            b += 0.2_f32;
        }
        for index in 0..VECTOR_LENGTH {
            x[index] = a + index as f32;
            y[index] = b + index as f32;
        }
        let mut accumulator = 0.0_f64;
        for index in 0..VECTOR_LENGTH {
            accumulator += f64::from(x[index]) * f64::from(y[index]);
        }
        total += accumulator;
    }
    unsafe { *output = total; }
    1
}
