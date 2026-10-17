const MAX_ANGLE: f64 = 1000.0;

#[no_mangle]
pub unsafe extern "C" fn rotation_matrix(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 1 { return -1; }
    let theta = *input;
    if !theta.is_finite() || !(-MAX_ANGLE..=MAX_ANGLE).contains(&theta) { return -1; }
    let cosine = theta.cos();
    let sine = theta.sin();
    let matrix = [cosine, -sine, sine, cosine];
    if output.is_null() || output_capacity < matrix.len() { return -2; }
    for (index, value) in matrix.iter().enumerate() { *output.add(index) = *value; }
    matrix.len() as i64
}
