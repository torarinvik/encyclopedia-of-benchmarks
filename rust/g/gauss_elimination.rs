fn put_f64_le(out: &mut [u8], offset: usize, value: f64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn gauss_elimination(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=8).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + n*n + n || values[1..].iter().any(|&x| !(-100..=100).contains(&x)) { return -1; }
    let mut m = [[0.0_f32; 9]; 8];
    for r in 0..n { for c in 0..n { m[r][c] = values[1+r*n+c] as f32; } m[r][n] = values[1+n*n+r] as f32; }
    for i in 0..n-1 {
        let mut pivot=i;
        for j in i..n { if m[j][i].abs() > m[pivot][i].abs() { pivot=j; } }
        if m[pivot][i] == 0.0 { return -1; }
        if pivot != i { for l in 0..=n { let t=m[i][l]; m[i][l]=m[pivot][l]; m[pivot][l]=t; } }
        for j in i+1..n {
            let tmp = -(m[j][i] / m[i][i]);
            for l in 0..=n { m[j][l] = m[j][l] + m[i][l]*tmp; }
        }
    }
    if m[n-1][n-1] == 0.0 { return -1; }
    if output.is_null() || capacity < n*8 { return -2; }
    let mut ans=[0.0_f32;8];
    for k in (0..n).rev() {
        let mut mul=0.0_f32;
        for l in (k+1..n).rev() { mul = mul + m[k][l]*ans[l]; }
        ans[k]=(m[k][n]-mul)/m[k][k];
    }
    let out=std::slice::from_raw_parts_mut(output,n*8);
    for i in 0..n { put_f64_le(out,i*8,((ans[i] as f64*100.0).round_ties_even()/100.0)); }
    (n*8) as i64
}
