use std::slice;

const MAX_INPUT: usize = 35;
const MAX_OUTPUT: usize = 38;
const MIN_EIGENGAP: f64 = 1e-8;
const JACOBI_TOLERANCE: f64 = 1e-14;

fn diagonalize(a: &mut [[f64; 4]; 4], vectors: &mut [[f64; 4]; 4], n: usize) -> Option<[f64; 4]> {
    for i in 0..n { for j in 0..n { vectors[i][j] = if i == j { 1.0 } else { 0.0 }; }}
    let mut converged = false;
    for sweep in 0..=64 {
        let mut largest: f64 = 0.0;
        for p in 0..n { for q in p + 1..n { largest = largest.max(a[p][q].abs()); }}
        if largest <= JACOBI_TOLERANCE { converged = true; break; }
        if sweep == 64 { break; }
        for p in 0..n { for q in p + 1..n {
            let apq = a[p][q];
            if apq.abs() <= JACOBI_TOLERANCE { continue; }
            let tau = (a[q][q] - a[p][p]) / (2.0 * apq);
            let sign = if tau >= 0.0 { 1.0 } else { -1.0 };
            let t = sign / (tau.abs() + (1.0 + tau * tau).sqrt());
            let c = 1.0 / (1.0 + t * t).sqrt();
            let s = t * c;
            let app = a[p][p]; let aqq = a[q][q];
            a[p][p] = app - t * apq; a[q][q] = aqq + t * apq;
            a[p][q] = 0.0; a[q][p] = 0.0;
            for r in 0..n {
                if r != p && r != q {
                    let arp = a[r][p]; let arq = a[r][q];
                    a[r][p] = c * arp - s * arq; a[p][r] = a[r][p];
                    a[r][q] = s * arp + c * arq; a[q][r] = a[r][q];
                }
                let vrp = vectors[r][p]; let vrq = vectors[r][q];
                vectors[r][p] = c * vrp - s * vrq;
                vectors[r][q] = s * vrp + c * vrq;
            }
        }}
    }
    if !converged { return None; }
    let mut values = [0.0; 4];
    for i in 0..n { values[i] = a[i][i]; }
    for i in 0..n { for j in i + 1..n { if values[j] > values[i] {
        values.swap(i, j);
        for row in 0..n { vectors[row].swap(i, j); }
    }}}
    Some(values)
}

fn compute(values: &[f64]) -> Option<[f64; MAX_OUTPUT]> {
    if values.len() < 3 || values.len() > MAX_INPUT || values.iter().any(|x| !x.is_finite()) { return None; }
    let (nv, fv, cv) = (values[0], values[1], values[2]);
    if nv < 3.0 || nv > 8.0 || nv.fract() != 0.0 || fv < 2.0 || fv > 4.0 || fv.fract() != 0.0 ||
       cv < 1.0 || cv > 4.0 || cv.fract() != 0.0 { return None; }
    let (n, f, k) = (nv as usize, fv as usize, cv as usize);
    if n <= f || k > f || values.len() != 3 + n * f { return None; }
    let mut rows = [[0.0; 4]; 8]; let mut means = [0.0; 4];
    for r in 0..n { for c in 0..f {
        let x = values[3 + r * f + c];
        if x.fract() != 0.0 || !(-9.0..=9.0).contains(&x) { return None; }
        rows[r][c] = x; means[c] += x;
        if !means[c].is_finite() { return None; }
    }}
    for c in 0..f { means[c] /= n as f64; }
    let mut variances = [0.0; 4];
    for r in 0..n { for c in 0..f { let d = rows[r][c] - means[c]; variances[c] += d * d; }}
    let mut scales = [0.0; 4];
    for c in 0..f {
        variances[c] /= n as f64;
        if !(variances[c] > 0.0) || !variances[c].is_finite() { return None; }
        scales[c] = variances[c].sqrt();
    }
    let mut z = [[0.0; 4]; 8]; let mut pca_means = [0.0; 4];
    for r in 0..n { for c in 0..f { z[r][c] = (rows[r][c] - means[c]) / scales[c]; pca_means[c] += z[r][c]; }}
    for c in 0..f { pca_means[c] /= n as f64; }
    let mut centered = [[0.0; 4]; 8];
    for r in 0..n { for c in 0..f { centered[r][c] = z[r][c] - pca_means[c]; }}
    let mut cov = [[0.0; 4]; 4];
    for i in 0..f { for j in i..f {
        let mut sum = 0.0;
        for r in 0..n { sum += centered[r][i] * centered[r][j]; }
        cov[i][j] = sum / (n - 1) as f64; cov[j][i] = cov[i][j];
    }}
    let mut vectors = [[0.0; 4]; 4];
    let eigenvalues = diagonalize(&mut cov, &mut vectors, f)?;
    for i in 0..f {
        if !(eigenvalues[i] > 0.0) || !eigenvalues[i].is_finite() ||
           (i + 1 < f && eigenvalues[i] - eigenvalues[i + 1] <= MIN_EIGENGAP) { return None; }
    }
    let total: f64 = eigenvalues[..f].iter().sum();
    if !(total > 0.0) || !total.is_finite() { return None; }
    let mut scores = [[0.0; 8]; 4];
    for component in 0..k {
        for r in 0..n { for c in 0..f { scores[component][r] += centered[r][c] * vectors[c][component]; }}
        let mut pivot = 0;
        for r in 1..n { if scores[component][r].abs() > scores[component][pivot].abs() { pivot = r; }}
        if scores[component][pivot] < 0.0 { for r in 0..n { scores[component][r] = -scores[component][r]; }}
    }
    let mut output = [0.0; MAX_OUTPUT]; output[0] = n as f64; output[1] = k as f64;
    let mut pos = 2;
    for r in 0..n { for component in 0..k { output[pos] = scores[component][r]; pos += 1; }}
    for component in 0..k { output[pos] = eigenvalues[component] / total; pos += 1; }
    if output[..pos].iter().any(|x| !x.is_finite()) { return None; }
    Some(output)
}

#[no_mangle]
pub unsafe extern "C" fn principle_component_analysis(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length > MAX_INPUT { return -1; }
    let values = unsafe { slice::from_raw_parts(input, input_length) };
    let result = match compute(values) { Some(value) => value, None => return -1 };
    let n = result[0] as usize; let k = result[1] as usize;
    let count = 2 + n * k + k;
    if output.is_null() || output_capacity < count { return -2; }
    for i in 0..count { unsafe { *output.add(i) = result[i]; } }
    count as i64
}
