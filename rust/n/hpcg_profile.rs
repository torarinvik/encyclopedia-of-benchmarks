use std::slice;

const MAX_N: usize = 32;
const MAX_COARSE: usize = 16;
const MAX_STEPS: usize = 12;
const MAX_MICRO: i64 = 1_000_000_000;
const SCALE: f64 = 1_000_000.0;
const RP: usize = 3;

fn columns_at(n: usize) -> usize { 4 + n }
fn values_at(n: usize, nnz: usize) -> usize { 4 + n + nnz }
fn rhs_at(n: usize, nnz: usize) -> usize { values_at(n, nnz) + nnz }

fn valid(v: &[i64], diagonal: &mut [f64; MAX_N]) -> Option<(usize, usize, usize)> {
    if v.len() < 8 || v.len() > 452 || !(1..=MAX_N as i64).contains(&v[0]) ||
       !(1..=MAX_STEPS as i64).contains(&v[1]) || v[1] > v[0] || v[2] < v[0] || v[2] > 6 * v[0] { return None; }
    let n = v[0] as usize; let steps = v[1] as usize; let nnz = v[2] as usize;
    if v.len() != 4 + 2 * n + 2 * nnz || v[RP] != 0 || v[RP + n] != nnz as i64 { return None; }
    let col = columns_at(n); let val = values_at(n, nnz); let rhs = rhs_at(n, nnz);
    for row in 0..n {
        let begin = v[RP + row]; let end = v[RP + row + 1];
        if begin < 0 || begin >= end || end > nnz as i64 || end - begin > 6 { return None; }
        let mut diag = 0_i64; let mut off = 0_i64; let mut previous = -1_i64;
        for edge in begin as usize..end as usize {
            let c = v[col + edge]; let a = v[val + edge];
            if c < 0 || c >= n as i64 || c <= previous || a == 0 || a < -MAX_MICRO || a > MAX_MICRO { return None; }
            previous = c;
            if c as usize == row { diag = a; } else { off += a.abs(); }
        }
        if diag <= 0 || diag <= off || v[rhs + row] < -MAX_MICRO || v[rhs + row] > MAX_MICRO { return None; }
        diagonal[row] = diag as f64 / SCALE;
    }
    for row in 0..n {
        for edge in v[RP + row] as usize..v[RP + row + 1] as usize {
            let c = v[col + edge] as usize;
            let found = (v[RP + c] as usize..v[RP + c + 1] as usize)
                .any(|rev| v[col + rev] == row as i64 && v[val + rev] == v[val + edge]);
            if !found { return None; }
        }
    }
    Some((n, steps, nnz))
}

fn matvec(n: usize, nnz: usize, v: &[i64], x: &[f64; MAX_N], y: &mut [f64; MAX_N]) {
    let col = columns_at(n); let val = values_at(n, nnz);
    for row in 0..n {
        let mut sum = 0.0;
        for edge in v[RP + row] as usize..v[RP + row + 1] as usize { sum += v[val + edge] as f64 / SCALE * x[v[col + edge] as usize]; }
        y[row] = sum;
    }
}

fn coarse_solve(n: usize, nnz: usize, v: &[i64], rhs: &[f64; MAX_COARSE], out: &mut [f64; MAX_COARSE]) -> bool {
    let cn = (n + 1) / 2; let col = columns_at(n); let val = values_at(n, nnz);
    let mut a = [[0.0; MAX_COARSE]; MAX_COARSE]; let mut l = [[0.0; MAX_COARSE]; MAX_COARSE];
    for row in 0..n { for edge in v[RP + row] as usize..v[RP + row + 1] as usize { a[row / 2][v[col + edge] as usize / 2] += v[val + edge] as f64 / SCALE; } }
    for i in 0..cn { for j in 0..=i {
        let mut value = a[i][j]; for k in 0..j { value -= l[i][k] * l[j][k]; }
        if i == j { if !(value > 0.0) || !value.is_finite() { return false; } l[i][j] = value.sqrt(); }
        else { l[i][j] = value / l[j][j]; }
    } }
    let mut y = [0.0; MAX_COARSE];
    for i in 0..cn { let mut value = rhs[i]; for j in 0..i { value -= l[i][j] * y[j]; } y[i] = value / l[i][i]; }
    for ii in (0..cn).rev() { let mut value = y[ii]; for j in ii + 1..cn { value -= l[j][ii] * out[j]; } out[ii] = value / l[ii][ii]; }
    true
}

fn precondition(n: usize, nnz: usize, v: &[i64], d: &[f64; MAX_N], r: &[f64; MAX_N], z: &mut [f64; MAX_N]) -> bool {
    let col = columns_at(n); let val = values_at(n, nnz);
    let mut pre = [0.0; MAX_N]; let mut product = [0.0; MAX_N];
    for row in 0..n {
        let mut value = r[row];
        for edge in v[RP + row] as usize..v[RP + row + 1] as usize { let c = v[col + edge] as usize; if c < row { value -= v[val + edge] as f64 / SCALE * pre[c]; } }
        pre[row] = value / d[row];
    }
    matvec(n, nnz, v, &pre, &mut product);
    let mut coarse_rhs = [0.0; MAX_COARSE]; let mut coarse_x = [0.0; MAX_COARSE];
    for row in 0..n { coarse_rhs[row / 2] += r[row] - product[row]; }
    if !coarse_solve(n, nnz, v, &coarse_rhs, &mut coarse_x) { return false; }
    let mut middle = [0.0; MAX_N];
    for row in 0..n { middle[row] = pre[row] + coarse_x[row / 2]; }
    matvec(n, nnz, v, &middle, &mut product);
    let mut post_r = [0.0; MAX_N]; let mut post = [0.0; MAX_N];
    for row in 0..n { post_r[row] = r[row] - product[row]; }
    for ii in (0..n).rev() {
        let mut value = post_r[ii];
        for edge in v[RP + ii] as usize..v[RP + ii + 1] as usize { let c = v[col + edge] as usize; if c > ii { value -= v[val + edge] as f64 / SCALE * post[c]; } }
        post[ii] = value / d[ii];
    }
    for row in 0..n { z[row] = middle[row] + post[row]; }
    true
}

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    for (i, byte) in value.to_le_bytes().iter().enumerate() { output.add(offset + i).write(*byte); }
}

#[no_mangle]
pub unsafe extern "C" fn hpcg_profile(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 8 || length > 452 { return -1; }
    let v = slice::from_raw_parts(values, length);
    let mut d = [0.0; MAX_N];
    let (n, steps, nnz) = match valid(v, &mut d) { Some(x) => x, None => return -1 };
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let rhs = rhs_at(n, nnz);
    let mut b = [0.0; MAX_N]; let mut x = [0.0; MAX_N]; let mut r = [0.0; MAX_N];
    let mut z = [0.0; MAX_N]; let mut p = [0.0; MAX_N]; let mut q = [0.0; MAX_N]; let mut ax = [0.0; MAX_N];
    let mut b2 = 0.0;
    for i in 0..n { b[i] = v[rhs + i] as f64 / SCALE; r[i] = b[i]; b2 += b[i] * b[i]; }
    if b2 > 0.0 {
        if !precondition(n, nnz, v, &d, &r, &mut z) { return -1; }
        p = z;
        let mut rho = 0.0; for i in 0..n { rho += r[i] * z[i]; }
        if !(rho > 0.0) || !rho.is_finite() { return -1; }
        for _ in 0..steps {
            matvec(n, nnz, v, &p, &mut q);
            let mut curvature = 0.0; for i in 0..n { curvature += p[i] * q[i]; }
            if !(curvature > 0.0) || !curvature.is_finite() { return -1; }
            let alpha = rho / curvature;
            for i in 0..n { x[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            let mut r2 = 0.0; for i in 0..n { r2 += r[i] * r[i]; }
            if r2 <= b2 * 1.0e-28 { break; }
            let mut next_z = [0.0; MAX_N]; if !precondition(n, nnz, v, &d, &r, &mut next_z) { return -1; }
            let mut next_rho = 0.0; for i in 0..n { next_rho += r[i] * next_z[i]; }
            if !(next_rho > 0.0) || !next_rho.is_finite() { return -1; }
            let beta = next_rho / rho;
            for i in 0..n { z[i] = next_z[i]; p[i] = z[i] + beta * p[i]; }
            rho = next_rho;
        }
    }
    matvec(n, nnz, v, &x, &mut ax);
    let mut r2 = 0.0;
    for i in 0..n { let e = b[i] - ax[i]; r2 += e * e; if !x[i].is_finite() { return -1; } write_f64_le(output, 8 * i, x[i]); }
    let norm = r2.sqrt(); if !norm.is_finite() { return -1; }
    write_f64_le(output, 8 * n, norm);
    bytes as i64
}
