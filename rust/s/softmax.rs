#[no_mangle]
pub unsafe extern "C" fn softmax(values: *const f64, length: usize,
                                  output: *mut f64, capacity: usize) -> i64 {
    if values.is_null() || length == 0 || length > 64 { return -1; }
    let mut input = [0.0_f64; 64];
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !value.is_finite() || value < -20.0 || value > 20.0 { return -1; }
        input[index] = value;
    }
    if output.is_null() || capacity < length { return -2; }

    let mut exponentials = [0.0_f32; 64];
    let mut total = 0.0_f32;
    for index in 0..length {
        let exponential = std::f32::consts::E.powf(input[index] as f32);
        exponentials[index] = exponential;
        total += exponential;
    }
    for index in 0..length {
        unsafe { *output.add(index) = (exponentials[index] / total) as f64; }
    }
    length as i64
}
