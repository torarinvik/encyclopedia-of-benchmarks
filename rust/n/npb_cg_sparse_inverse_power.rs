use std::slice;

const MAX_N: usize = 32;
const MAX_OUTER: usize = 8;
const MAX_STEPS: usize = 25;
const MAX_MICRO: i64 = 1_000_000_000;
const SCALE: f64 = 1_000_000.0;

fn valid(v: &[i64]) -> Option<(usize, usize, usize, usize)> {
    if v.len() < 8 || !(1..=MAX_N as i64).contains(&v[0])
        || !(1..=MAX_OUTER as i64).contains(&v[1])
        || !(1..=MAX_STEPS as i64).contains(&v[2]) || v[2] > v[0]
        || !(-MAX_MICRO..=MAX_MICRO).contains(&v[3]) || v[4] < v[0]
        || v[4] > 6 * v[0] { return None; }
    let n = v[0] as usize;
    let outer = v[1] as usize;
    let steps = v[2] as usize;
    let nnz = v[4] as usize;
    if v.len() != n + 6 + 2 * nnz { return None; }
    let rp = 5;
    let col = rp + n + 1;
    let val = col + nnz;
    if v[rp] != 0 || v[rp + n] != nnz as i64 { return None; }
    for row in 0..n {
        let begin = v[rp + row];
        let end = v[rp + row + 1];
        if begin < 0 || begin >= end || end > nnz as i64 { return None; }
        let mut diagonal = 0_i64;
        let mut off_sum = 0_i64;
        let mut previous = -1_i64;
        for edge in begin as usize..end as usize {
            let c = v[col + edge];
            let a = v[val + edge];
            if c < 0 || c >= n as i64 || c <= previous || a == 0
                || !(-MAX_MICRO..=MAX_MICRO).contains(&a) { return None; }
            previous = c;
            if c as usize == row { diagonal = a; } else { off_sum += a.abs(); }
        }
        if diagonal <= 0 || diagonal <= off_sum { return None; }
    }
    for row in 0..n {
        for edge in v[rp + row] as usize..v[rp + row + 1] as usize {
            let c = v[col + edge] as usize;
            let a = v[val + edge];
            let mut found = false;
            for reverse in v[rp + c] as usize..v[rp + c + 1] as usize {
                if v[col + reverse] == row as i64 && v[val + reverse] == a {
                    found = true;
                    break;
                }
            }
            if !found { return None; }
        }
    }
    Some((n, outer, steps, nnz))
}

fn matvec(n: usize, nnz: usize, v: &[i64], vector: &[f64; MAX_N], product: &mut [f64; MAX_N]) {
    let rp = 5;
    let col = rp + n + 1;
    let val = col + nnz;
    for row in 0..n {
        let mut sum = 0.0;
        for edge in v[rp + row] as usize..v[rp + row + 1] as usize {
            sum += (v[val + edge] as f64 / SCALE) * vector[v[col + edge] as usize];
        }
        product[row] = sum;
    }
}

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { output.add(offset + index).write(*byte); }
}

#[no_mangle]
pub unsafe extern "C" fn npb_cg_sparse_inverse_power(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 8 || length > MAX_N + 6 + 2 * (MAX_N * 6) { return -1; }
    let v = slice::from_raw_parts(values, length);
    let (n, outer_count, steps, nnz) = match valid(v) {
        Some(parsed) => parsed,
        None => return -1,
    };
    let output_bytes = outer_count * 16;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut x = [0.0; MAX_N];
    let mut z = [0.0; MAX_N];
    let mut r = [0.0; MAX_N];
    let mut p = [0.0; MAX_N];
    let mut q = [0.0; MAX_N];
    let mut az = [0.0; MAX_N];
    for i in 0..n { x[i] = 1.0; }
    for outer in 0..outer_count {
        let mut rhs_squared = 0.0;
        for i in 0..n {
            z[i] = 0.0;
            r[i] = x[i];
            p[i] = x[i];
            rhs_squared += r[i] * r[i];
        }
        let mut residual_squared = rhs_squared;
        for _step in 0..steps {
            if residual_squared <= 0.0 { break; }
            matvec(n, nnz, v, &p, &mut q);
            let mut denominator = 0.0;
            for i in 0..n { denominator += p[i] * q[i]; }
            if !(denominator > 0.0) || !denominator.is_finite() { return -1; }
            let alpha = residual_squared / denominator;
            for i in 0..n { z[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            let mut next_squared = 0.0;
            for i in 0..n { next_squared += r[i] * r[i]; }
            if next_squared <= rhs_squared * 1.0e-28 {
                residual_squared = next_squared;
                break;
            }
            let beta = next_squared / residual_squared;
            for i in 0..n { p[i] = r[i] + beta * p[i]; }
            residual_squared = next_squared;
        }
        matvec(n, nnz, v, &z, &mut az);
        let mut explicit_squared = 0.0;
        let mut x_dot_z = 0.0;
        let mut z_squared = 0.0;
        for i in 0..n {
            let difference = x[i] - az[i];
            explicit_squared += difference * difference;
            x_dot_z += x[i] * z[i];
            z_squared += z[i] * z[i];
        }
        if !(x_dot_z > 0.0) || !(z_squared > 0.0) ||
            !x_dot_z.is_finite() || !z_squared.is_finite() { return -1; }
        let estimate = v[3] as f64 / SCALE + 1.0 / x_dot_z;
        let residual_norm = explicit_squared.sqrt();
        if !estimate.is_finite() || !residual_norm.is_finite() { return -1; }
        write_f64_le(output, outer * 16, estimate);
        write_f64_le(output, outer * 16 + 8, residual_norm);
        let z_norm = z_squared.sqrt();
        for i in 0..n { x[i] = z[i] / z_norm; }
    }
    output_bytes as i64
}
