const COMPONENT_LIMIT: f64 = 1_000_000.0;
const EPSILON: f64 = 1.0e-9;

fn dot_product(a: &[f32; 3], b: &[f32; 3]) -> f32 {
    let mut dot = a[0] * b[0];
    dot += a[1] * b[1];
    dot += a[2] * b[2];
    dot
}

fn vector_norm(vector: &[f32; 3]) -> f32 {
    dot_product(vector, vector).sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vectors_3d(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len == 0 || input_len > 64 { return -1; }
    let values = std::slice::from_raw_parts(input, input_len);
    let operation_value = values[0];
    if !operation_value.is_finite() || !(0.0..=7.0).contains(&operation_value)
        || operation_value.fract() != 0.0 { return -1; }
    let operation = operation_value as usize;
    let required_length = if operation <= 3 || operation == 7 { 7 } else { 4 };
    if input_len != required_length { return -1; }

    let mut a = [0.0f32; 3];
    let mut b = [0.0f32; 3];
    for index in 0..3 {
        let value = values[1 + index];
        if !value.is_finite() || value.abs() > COMPONENT_LIMIT { return -1; }
        a[index] = value as f32;
    }
    if required_length == 7 {
        for index in 0..3 {
            let value = values[4 + index];
            if !value.is_finite() || value.abs() > COMPONENT_LIMIT { return -1; }
            b[index] = value as f32;
        }
    }

    let mut result = [0.0f64; 9];
    let result_length: usize;
    match operation {
        0 => {
            result_length = 3;
            for index in 0..3 { result[index] = (a[index] + b[index]) as f64; }
        }
        1 => {
            result_length = 3;
            for index in 0..3 { result[index] = (a[index] - b[index]) as f64; }
        }
        2 => {
            result_length = 1;
            result[0] = dot_product(&a, &b) as f64;
        }
        3 => {
            result_length = 3;
            result[0] = (a[1] * b[2] - a[2] * b[1]) as f64;
            result[1] = (-a[0] * b[2] + a[2] * b[0]) as f64;
            result[2] = (a[0] * b[1] - a[1] * b[0]) as f64;
        }
        4 => {
            result_length = 1;
            result[0] = vector_norm(&a) as f64;
        }
        5 => {
            result_length = 3;
            let norm = vector_norm(&a);
            if (norm as f64) >= EPSILON && norm != 1.0f32 {
                for index in 0..3 { result[index] = (a[index] / norm) as f64; }
            }
        }
        6 => {
            result_length = 9;
            result = [0.0, -(a[2] as f64), a[1] as f64,
                      a[2] as f64, 0.0, -(a[0] as f64),
                      -(a[1] as f64), a[0] as f64, 0.0];
        }
        _ => {
            result_length = 1;
            let norm_a = vector_norm(&a);
            let norm_b = vector_norm(&b);
            if (norm_a as f64) < EPSILON || (norm_b as f64) < EPSILON {
                result[0] = 2.0f64.acos();
            } else {
                let cosine = dot_product(&a, &b) / (norm_a * norm_b);
                result[0] = (cosine as f64).acos();
            }
        }
    }

    if output.is_null() || output_capacity < result_length { return -2; }
    for index in 0..result_length { *output.add(index) = result[index]; }
    result_length as i64
}
