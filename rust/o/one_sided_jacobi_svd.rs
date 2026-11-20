#[no_mangle]
pub extern "C" fn one_sided_jacobi_svd(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 39 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let m64 = values[0];
    let n64 = values[1];
    if !(1..=6).contains(&n64) || m64 < n64 || m64 > 6 { return -1; }
    let (m, n) = (m64 as usize, n64 as usize);
    if length != 2 + m * n { return -1; }
    let mut a = [[0.0_f64; 6]; 6];
    for r in 0..m {
        for col in 0..n {
            let x = values[2 + r * n + col];
            if !(-8..=8).contains(&x) { return -1; }
            a[r][col] = x as f64;
        }
    }
    let mut converged = false;
    for _ in 0..128 {
        let mut changed = false;
        for p in 0..n {
            for q in p + 1..n {
                let (mut alpha, mut beta, mut gamma) = (0.0, 0.0, 0.0);
                for r in 0..m { let (x,y)=(a[r][p],a[r][q]); alpha+=x*x; beta+=y*y; gamma+=x*y; }
                if alpha == 0.0 || beta == 0.0 || gamma.abs() <= 1.0e-14 * (alpha * beta).sqrt() { continue; }
                let tau = (beta - alpha) / (2.0 * gamma);
                let t = if tau == 0.0 { 1.0 } else { tau.signum() / (tau.abs() + (1.0 + tau * tau).sqrt()) };
                let c = 1.0 / (1.0 + t * t).sqrt();
                let s = c * t;
                for r in 0..m { let (x,y)=(a[r][p],a[r][q]); a[r][p]=c*x-s*y; a[r][q]=s*x+c*y; }
                changed = true;
            }
        }
        if !changed { converged = true; break; }
    }
    if !converged { return -1; }
    let mut sigma = [0.0_f64; 6];
    for col in 0..n { for r in 0..m { sigma[col] += a[r][col] * a[r][col]; } sigma[col] = sigma[col].sqrt(); }
    for i in 0..n { for j in i + 1..n { if sigma[j] > sigma[i] { sigma.swap(i, j); } } }
    let signature: f64 = (0..n).map(|i| (i + 1) as f64 * sigma[i]).sum();
    (signature * 1000.0 + 0.5) as i64
}
