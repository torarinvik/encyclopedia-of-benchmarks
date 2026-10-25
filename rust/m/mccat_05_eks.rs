/****
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
****/
const MIN_N: usize = 3;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 2 + MAX_N * MAX_N;
const INPUT_SCALE: f64 = 1_000_000.0;
const OUTPUT_SCALE: f64 = 1_000.0;
const QR_EPSILON: f64 = 1.0e-10;
const MAX_QR_STEPS: usize = 4096;

fn givens(a: f64, b: f64) -> (f64, f64) {
    if b == 0.0 { return (0.0, 1.0); }
    if b.abs() > a.abs() {
        let t = -a / b;
        let s = 1.0 / (1.0 + t * t).sqrt();
        (s, s * t)
    } else {
        let t = -b / a;
        let c = 1.0 / (1.0 + t * t).sqrt();
        (c * t, c)
    }
}

fn apply_givens(a: &mut [f64; 64], n: usize, s: f64, c: f64, i: usize, j: usize, start: usize, end: usize) {
    for k in start..=end {
        let (x, y) = (a[i * n + k], a[j * n + k]);
        a[i * n + k] = c * x - s * y;
        a[j * n + k] = s * x + c * y;
    }
    for k in start..=end {
        let (x, y) = (a[k * n + i], a[k * n + j]);
        a[k * n + i] = c * x - s * y;
        a[k * n + j] = s * x + c * y;
    }
}

fn reduce_band(a: &mut [f64; 64], n: usize, bandwidth: usize) {
    for i in (2..=bandwidth).rev() {
        for j in 0..n - i {
            let (s, c) = givens(a[j * n + j + i - 1], a[j * n + j + i]);
            let end = (j + 2 * i).min(n - 1);
            apply_givens(a, n, s, c, j + i - 1, j + i, j, end);
            let mut m = j + i;
            while m < n - i {
                let (s, c) = givens(a[(m - 1) * n + m + i - 1], a[(m - 1) * n + m + i]);
                let end = (m + 2 * i).min(n - 1);
                apply_givens(a, n, s, c, m + i - 1, m + i, m - 1, end);
                m += i;
            }
        }
    }
}

fn qr_iterate(a: &mut [f64; 64], n: usize) -> bool {
    let mut steps = 0;
    loop {
        for i in 0..n - 1 {
            if a[(i + 1) * n + i].abs() < (a[i * n + i].abs() + a[(i + 1) * n + i + 1].abs()) * QR_EPSILON {
                a[(i + 1) * n + i] = 0.0;
                a[i * n + i + 1] = 0.0;
            }
        }
        let mut q = n - 1;
        while q > 0 && a[(q - 1) * n + q] == 0.0 { q -= 1; }
        if q == 0 { return true; }
        steps += 1;
        if steps > MAX_QR_STEPS { return false; }
        let mut p = q;
        while p > 0 && a[(p - 1) * n + p] != 0.0 { p -= 1; }
        let d = (a[(q - 1) * n + q - 1] - a[q * n + q]) / 2.0;
        let t = a[q * n + q - 1] * a[q * n + q - 1];
        let sign = if d < 0.0 { -1.0 } else { 1.0 };
        let mu = a[q * n + q] - t / (d + sign * (d * d + t).sqrt());
        let (mut x, mut z) = (a[p * n + p] - mu, a[(p + 1) * n + p]);
        for i in p..q {
            let (s, c) = givens(x, z);
            let l = if i > p { i - 1 } else { p };
            let m = q.min(i + 2);
            for k in l..=m {
                let (u, v) = (a[i * n + k], a[(i + 1) * n + k]);
                a[i * n + k] = c * u - s * v;
                a[(i + 1) * n + k] = s * u + c * v;
            }
            for k in l..=m {
                let (u, v) = (a[k * n + i], a[k * n + i + 1]);
                a[k * n + i] = c * u - s * v;
                a[k * n + i + 1] = s * u + c * v;
            }
            if i < q - 1 { x = a[(i + 1) * n + i]; z = a[(i + 2) * n + i]; }
        }
    }
}

fn project(value: f64) -> i32 {
    let scaled = value * OUTPUT_SCALE;
    if scaled >= 0.0 { (scaled + 0.5).floor() as i32 } else { (scaled - 0.5).ceil() as i32 }
}
fn before(left: f64, right: f64) -> bool {
    left.abs() > right.abs() || (left.abs() == right.abs() && left < right)
}
fn write_i32_le(value: i32, output: &mut [u8; 32], offset: usize) {
    let bytes = value.to_le_bytes();
    output[offset..offset + 4].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn mccat_05_eks(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    let bw64 = values[1];
    if n64 < MIN_N as i64 || n64 > MAX_N as i64 || !(2..=5).contains(&bw64) || bw64 >= n64 as i64 { return -1; }
    let n = n64 as usize;
    let bandwidth = bw64 as usize;
    if length != 2 + n * n { return -1; }
    let mut a = [0.0; 64];
    for row in 0..n {
        for column in 0..n {
            let value = values[2 + row * n + column];
            if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
            if row > column && value != values[2 + column * n + row] { return -1; }
            if row.abs_diff(column) > bandwidth && value != 0 { return -1; }
            a[row * n + column] = value as f64 / INPUT_SCALE;
        }
    }
    let required = n * 4;
    if output.is_null() || capacity < required { return -2; }
    reduce_band(&mut a, n, bandwidth);
    if !qr_iterate(&mut a, n) { return -1; }
    let mut eigenvalues = [0.0; 8];
    for i in 0..n { eigenvalues[i] = a[i * n + i]; }
    for i in 1..n {
        let value = eigenvalues[i];
        let mut j = i;
        while j > 0 && before(value, eigenvalues[j - 1]) { eigenvalues[j] = eigenvalues[j - 1]; j -= 1; }
        eigenvalues[j] = value;
    }
    let mut staged = [0u8; 32];
    for i in 0..n { write_i32_le(project(eigenvalues[i]), &mut staged, 4 * i); }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required); }
    required as i64
}
