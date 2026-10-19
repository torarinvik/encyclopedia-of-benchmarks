const MAX_N: usize = 32;
const MAX_OUTPUT_BYTES: usize = (MAX_N + 1) * 8;
const EPSILON: f64 = 2.2204460492503131e-16;

fn abs(value: f64) -> f64 { if value < 0.0 { -value } else { value } }

fn sturm(diagonal: &[f64; MAX_N], off_diagonal: &[f64; MAX_N],
         beta: &[f64; MAX_N], n: usize, x: f64) -> usize {
    let mut negative_count = 0;
    let mut q = 1.0;
    for i in 0..n {
        if q != 0.0 { q = (diagonal[i] - x) - beta[i] / q; }
        else { q = (diagonal[i] - x) - abs(off_diagonal[i]) / EPSILON; }
        if q < 0.0 { negative_count += 1; }
    }
    negative_count
}

fn store_f64_le(value: f64, staged: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize) {
    let bytes = value.to_le_bytes();
    staged[*used..*used + 8].copy_from_slice(&bytes);
    *used += 8;
}

fn solve(n: usize, staged: &mut [u8; MAX_OUTPUT_BYTES]) -> usize {
    let mut diagonal = [0.0; MAX_N];
    let mut off_diagonal = [0.0; MAX_N];
    let mut beta = [0.0; MAX_N];
    let mut eigenvalues = [0.0; MAX_N + 1];
    let mut lower_bounds = [0.0; MAX_N + 1];
    for i in 0..n {
        let value = (i + 1) as f64;
        diagonal[i] = value * value;
        diagonal[i] = diagonal[i] * diagonal[i];
        off_diagonal[i] = i as f64;
        beta[i] = off_diagonal[i] * off_diagonal[i];
    }
    beta[0] = 0.0;
    off_diagonal[0] = 0.0;

    let fudge = 1.01;
    let mut xmin = diagonal[n - 1] - fudge * abs(off_diagonal[n - 1]);
    let mut xmax = diagonal[n - 1] + fudge * abs(off_diagonal[n - 1]);
    for i in (0..n - 1).rev() {
        let h = fudge * (abs(off_diagonal[i]) + abs(off_diagonal[i + 1]));
        if diagonal[i] + h > xmax { xmax = diagonal[i] + h; }
        if diagonal[i] - h < xmin { xmin = diagonal[i] - h; }
    }
    let mut eps2 = EPSILON * if xmin + xmax > 0.0 { xmax } else { -xmin };
    let mut eps1 = EPSILON;
    if eps1 <= 0.0 { eps1 = eps2; }
    eps2 = 0.5 * eps1 + 7.0 * eps2;

    let mut x0 = xmax;
    for i in (1..=n).rev() {
        eigenvalues[i] = xmax;
        lower_bounds[i] = xmin;
    }
    let mut iterations = 0usize;
    for k in (1..=n).rev() {
        let mut xu = xmin;
        for i in (1..=k).rev() {
            if xu < lower_bounds[i] { xu = lower_bounds[i]; break; }
        }
        if x0 > eigenvalues[k] { x0 = eigenvalues[k]; }
        let mut x1 = (xu + x0) / 2.0;
        while x0 - xu > 2.0 * EPSILON * (abs(xu) + abs(x0)) + eps1 {
            iterations += 1;
            let count = sturm(&diagonal, &off_diagonal, &beta, n, x1);
            if count < k {
                if count < 1 {
                    xu = x1;
                    lower_bounds[1] = x1;
                } else {
                    xu = x1;
                    lower_bounds[count + 1] = x1;
                    if eigenvalues[count] > x1 { eigenvalues[count] = x1; }
                }
            } else { x0 = x1; }
            x1 = (xu + x0) / 2.0;
        }
        eigenvalues[k] = (xu + x0) / 2.0;
    }

    let mut used = 0;
    for i in 2..=n { store_f64_le(eigenvalues[i], staged, &mut used); }
    store_f64_le(eps2, staged, &mut used);
    store_f64_le(iterations as f64, staged, &mut used);
    used
}

#[no_mangle]
pub unsafe extern "C" fn mccat_bisect(values: *const i64, length: usize,
                                        output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let n_arg = *values;
    if n_arg < 2 || n_arg > MAX_N as i64 { return -1; }
    let n = n_arg as usize;
    let required = (n + 1) * 8;
    if output.is_null() || output_capacity < required { return -2; }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let used = solve(n, &mut staged);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, used);
    used as i64
}
