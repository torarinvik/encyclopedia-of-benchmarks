const MAX_ITERATIONS: i64 = 128;
const MAX_VECTOR_SIZE: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn misc_dt(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 2 { return -1; }
    let requested_iterations = unsafe { *input };
    let requested_size = unsafe { *input.add(1) };
    if !(requested_iterations >= 1.0 && requested_iterations <= MAX_ITERATIONS as f64)
        || requested_iterations.fract() != 0.0
        || !(requested_size >= 1.0 && requested_size <= MAX_VECTOR_SIZE as f64)
        || requested_size.fract() != 0.0 { return -1; }
    let iterations = requested_iterations as i64;
    let size = requested_size as usize;
    if output.is_null() || output_capacity < size { return -2; }

    let mut numerator = [0.0_f64; MAX_VECTOR_SIZE];
    let mut denominator = [0.0_f64; MAX_VECTOR_SIZE];
    for index in 0..size {
        let cosine = ((size - index) as f32).cos();
        let sine = (index as f32).sin();
        numerator[index] = 1.0000001 * cosine as f64;
        denominator[index] = 1.0 + 1e-10 * sine as f64;
    }
    for _ in 0..iterations {
        for index in 0..size { numerator[index] /= denominator[index]; }
    }
    for index in 0..size { unsafe { *output.add(index) = numerator[index]; } }
    size as i64
}
