const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 66;

fn finite(x: f64) -> bool { x.is_finite() }

fn factor(input: &[f64], staged: &mut [f64; 128]) -> Option<usize> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return None; }
    let raw_n = input[0];
    if !finite(raw_n) || raw_n.fract() != 0.0 || raw_n < 2.0 || raw_n > MAX_N as f64 { return None; }
    let n = raw_n as usize;
    if n % 2 != 0 || input.len() != 1 + n * n { return None; }

    let mut schur = [0.0_f64; 64];
    for row in 0..n {
        let mut off_sum = 0_i64;
        for col in 0..n {
            let x = input[1 + row * n + col];
            if !finite(x) || x.fract() != 0.0 { return None; }
            let value = x as i64;
            if row == col {
                if !(1..=16).contains(&value) { return None; }
            } else {
                if !(-2..=2).contains(&value) { return None; }
                off_sum += value.abs();
            }
            schur[row * n + col] = value as f64;
        }
        if schur[row * n + row] <= off_sum as f64 { return None; }
    }

    let mut lower = [0.0_f64; 64];
    let mut upper = [0.0_f64; 64];
    for k in (0..n).step_by(2) {
        let u00 = schur[k * n + k];
        let u01 = schur[k * n + k + 1];
        if !finite(u00) || u00 == 0.0 { return None; }
        let l10 = schur[(k + 1) * n + k] / u00;
        let u11 = schur[(k + 1) * n + k + 1] - l10 * u01;
        if !finite(l10) || !finite(u11) || u11 == 0.0 { return None; }
        lower[k * n + k] = 1.0;
        lower[(k + 1) * n + k] = l10;
        lower[(k + 1) * n + k + 1] = 1.0;
        upper[k * n + k] = u00;
        upper[k * n + k + 1] = u01;
        upper[(k + 1) * n + k + 1] = u11;

        for j in (k + 2..n).step_by(2) {
            for col in j..j + 2 {
                let s0 = schur[k * n + col];
                let s1 = schur[(k + 1) * n + col];
                upper[k * n + col] = s0;
                upper[(k + 1) * n + col] = s1 - l10 * s0;
            }
        }
        for i in (k + 2..n).step_by(2) {
            for row in i..i + 2 {
                let s0 = schur[row * n + k];
                let s1 = schur[row * n + k + 1];
                let l0 = s0 / u00;
                let l1 = (s1 - l0 * u01) / u11;
                lower[row * n + k] = l0;
                lower[row * n + k + 1] = l1;
            }
        }
        for i in (k + 2..n).step_by(2) {
            for j in (k + 2..n).step_by(2) {
                for row in i..i + 2 {
                    for col in j..j + 2 {
                        let update = lower[row * n + k] * upper[k * n + col]
                            + lower[row * n + k + 1] * upper[(k + 1) * n + col];
                        schur[row * n + col] -= update;
                    }
                }
            }
        }
    }
    for row in 0..n {
        lower[row * n + row] = 1.0;
        for col in row..n { upper[row * n + col] = schur[row * n + col]; }
    }
    let m = n * n;
    for i in 0..m {
        if !finite(lower[i]) || !finite(upper[i]) { return None; }
        staged[i] = lower[i];
        staged[m + i] = upper[i];
    }
    Some(2 * m)
}

#[no_mangle]
pub unsafe extern "C" fn blocked_lu_factorization(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let mut staged = [0.0_f64; 128];
    let length = match factor(values, &mut staged) { Some(value) => value, None => return -1 };
    if output.is_null() || output_capacity < length { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, length);
    length as i64
}
