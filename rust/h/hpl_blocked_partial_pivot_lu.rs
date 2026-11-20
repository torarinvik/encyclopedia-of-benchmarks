const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_OUTPUT_ELEMENTS: usize = 72;

fn exact_integer(x: f64, lo: i64, hi: i64) -> Option<i64> {
    if !x.is_finite() || x.fract() != 0.0 || x < lo as f64 || x > hi as f64 { return None; }
    Some(x as i64)
}

fn factor(input: &[f64], staged: &mut [f64; MAX_OUTPUT_ELEMENTS]) -> Option<usize> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return None; }
    let n = exact_integer(input[0], 2, MAX_N as i64)? as usize;
    if input.len() != 1 + n*n { return None; }
    let mut a = [0.0_f64; MAX_N*MAX_N];
    for i in 0..n*n { a[i] = exact_integer(input[i+1], -16, 16)? as f64; }
    let mut pivots = [0_usize; MAX_N];
    let mut panel = 0;
    while panel < n {
        let panel_end = (panel + 2).min(n);
        for col in panel..panel_end {
            let mut pivot_row = col;
            let mut pivot_magnitude = a[col*n+col].abs();
            for row in col+1..n {
                let magnitude = a[row*n+col].abs();
                if magnitude > pivot_magnitude { pivot_magnitude = magnitude; pivot_row = row; }
            }
            if !pivot_magnitude.is_finite() || pivot_magnitude == 0.0 { return None; }
            pivots[col] = pivot_row;
            if pivot_row != col {
                for j in 0..n { a.swap(col*n+j, pivot_row*n+j); }
            }
            let diagonal = a[col*n+col];
            if !diagonal.is_finite() || diagonal == 0.0 { return None; }
            for row in col+1..n {
                a[row*n+col] /= diagonal;
                if !a[row*n+col].is_finite() { return None; }
                let multiplier = a[row*n+col];
                for j in col+1..panel_end {
                    a[row*n+j] -= multiplier*a[col*n+j];
                    if !a[row*n+j].is_finite() { return None; }
                }
            }
        }
        for row in panel..panel_end {
            for col in panel_end..n {
                let mut value = a[row*n+col];
                for inner in panel..row { value -= a[row*n+inner]*a[inner*n+col]; }
                if !value.is_finite() { return None; }
                a[row*n+col] = value;
            }
        }
        for row in panel_end..n {
            for col in panel_end..n {
                let mut update = 0.0;
                for inner in panel..panel_end { update += a[row*n+inner]*a[inner*n+col]; }
                a[row*n+col] -= update;
                if !a[row*n+col].is_finite() { return None; }
            }
        }
        panel = panel_end;
    }
    for i in 0..n { staged[i] = pivots[i] as f64; }
    for i in 0..n*n {
        if !a[i].is_finite() { return None; }
        staged[n+i] = a[i];
    }
    Some(n+n*n)
}

#[no_mangle]
pub unsafe extern "C" fn hpl_blocked_partial_pivot_lu(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let mut staged = [0.0_f64; MAX_OUTPUT_ELEMENTS];
    let output_length = match factor(values, &mut staged) { Some(n) => n, None => return -1 };
    if output.is_null() || output_capacity < output_length { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_length);
    output_length as i64
}
