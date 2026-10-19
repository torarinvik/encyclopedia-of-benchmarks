const MAX_DIMENSION: usize = 64;
const INVALID_RESULT: f64 = -1e300;

fn matrix_entry(i: usize, j: usize) -> f64 {
    let triangular = (i + j) * (i + j + 1) / 2;
    1.0 / (triangular + i + 1) as f64
}

fn multiply_a(n: usize, input: &[f64; MAX_DIMENSION], output: &mut [f64; MAX_DIMENSION]) {
    for i in 0..n {
        let mut total = 0.0;
        for j in 0..n { total += matrix_entry(i, j) * input[j]; }
        output[i] = total;
    }
}

fn multiply_at(n: usize, input: &[f64; MAX_DIMENSION], output: &mut [f64; MAX_DIMENSION]) {
    for i in 0..n {
        let mut total = 0.0;
        for j in 0..n { total += matrix_entry(j, i) * input[j]; }
        output[i] = total;
    }
}

fn multiply_ata(n: usize, input: &[f64; MAX_DIMENSION],
                output: &mut [f64; MAX_DIMENSION], temporary: &mut [f64; MAX_DIMENSION]) {
    multiply_a(n, input, temporary);
    multiply_at(n, temporary, output);
}

#[no_mangle]
pub extern "C" fn spectral_norm(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = unsafe { *values };
    if input < 1 || input > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = input as usize;
    let mut u = [0.0; MAX_DIMENSION];
    let mut v = [0.0; MAX_DIMENSION];
    let mut temporary = [0.0; MAX_DIMENSION];
    for i in 0..n { u[i] = 1.0; }
    for _ in 0..10 {
        multiply_ata(n, &u, &mut v, &mut temporary);
        multiply_ata(n, &v, &mut u, &mut temporary);
    }
    let mut v_b_v = 0.0;
    let mut v_v = 0.0;
    for i in 0..n {
        v_b_v += u[i] * v[i];
        v_v += v[i] * v[i];
    }
    (v_b_v / v_v).sqrt()
}
