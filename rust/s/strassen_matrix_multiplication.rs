const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 129;

fn strassen_multiply(a: &[i64], b: &[i64], c: &mut [i64], n: usize) {
    if n == 1 { c[0] = a[0] * b[0]; return; }
    let half = n / 2;
    let mut x = [0i64; 16];
    let mut y = [0i64; 16];
    let mut m1 = [0i64; 16]; let mut m2 = [0i64; 16];
    let mut m3 = [0i64; 16]; let mut m4 = [0i64; 16];
    let mut m5 = [0i64; 16]; let mut m6 = [0i64; 16]; let mut m7 = [0i64; 16];
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[r * n + col] + a[(r + half) * n + col + half];
        y[i] = b[r * n + col] + b[(r + half) * n + col + half];
    }}
    strassen_multiply(&x, &y, &mut m1, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[(r + half) * n + col] + a[(r + half) * n + col + half]; y[i] = b[r * n + col];
    }}
    strassen_multiply(&x, &y, &mut m2, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[r * n + col]; y[i] = b[r * n + col + half] - b[(r + half) * n + col + half];
    }}
    strassen_multiply(&x, &y, &mut m3, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[(r + half) * n + col + half]; y[i] = b[(r + half) * n + col] - b[r * n + col];
    }}
    strassen_multiply(&x, &y, &mut m4, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[r * n + col] + a[r * n + col + half]; y[i] = b[(r + half) * n + col + half];
    }}
    strassen_multiply(&x, &y, &mut m5, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[(r + half) * n + col] - a[r * n + col]; y[i] = b[r * n + col] + b[r * n + col + half];
    }}
    strassen_multiply(&x, &y, &mut m6, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        x[i] = a[r * n + col + half] - a[(r + half) * n + col + half];
        y[i] = b[(r + half) * n + col] + b[(r + half) * n + col + half];
    }}
    strassen_multiply(&x, &y, &mut m7, half);
    for r in 0..half { for col in 0..half {
        let i = r * half + col;
        c[r * n + col] = m1[i] + m4[i] - m5[i] + m7[i];
        c[r * n + col + half] = m3[i] + m5[i];
        c[(r + half) * n + col] = m2[i] + m4[i];
        c[(r + half) * n + col + half] = m1[i] - m2[i] + m3[i] + m6[i];
    }}
}

#[no_mangle]
pub unsafe extern "C" fn strassen_matrix_multiplication(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value != 1 && n_value != 2 && n_value != 4 && n_value != 8 { return -1; }
    let n = n_value as usize;
    let cells = n * n;
    if length != 1 + 2 * cells || values[1..].iter().any(|&v| !(-2..=2).contains(&v)) { return -1; }
    let output_bytes = 8 * cells;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut result = [0i64; MAX_N * MAX_N];
    strassen_multiply(&values[1..1 + cells], &values[1 + cells..], &mut result[..cells], n);
    for (index, value) in result[..cells].iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
