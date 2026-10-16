const MAX_VALUES: usize = 19;

fn det3(m: &[i64; 9]) -> i64 {
    m[0] * (m[4] * m[8] - m[5] * m[7])
        - m[1] * (m[3] * m[8] - m[5] * m[6])
        + m[2] * (m[3] * m[7] - m[4] * m[6])
}

fn charpoly(m: &[i64; 9], n: usize) -> (i64, i64, i64) {
    let mut trace = 0;
    for i in 0..n { trace += m[i * n + i]; }
    if n == 1 { return (-trace, 0, 0); }
    if n == 2 { return (-trace, m[0] * m[3] - m[1] * m[2], 0); }
    let second = (m[0] * m[4] - m[1] * m[3])
        + (m[0] * m[8] - m[2] * m[6])
        + (m[4] * m[8] - m[5] * m[7]);
    (-trace, second, -det3(m))
}

fn disc3(a: i64, b: i64, c: i64) -> i64 {
    a*a*b*b - 4*b*b*b - 4*a*a*a*c - 27*c*c + 18*a*b*c
}

fn rank_singular(m: &[i64; 9], n: usize) -> usize {
    for r0 in 0..n { for r1 in (r0 + 1)..n {
        for c0 in 0..n { for c1 in (c0 + 1)..n {
            if m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0] != 0 { return 2; }
        }}
    }}
    if m[..n*n].iter().any(|&value| value != 0) { 1 } else { 0 }
}

fn shifted(m: &[i64; 9], n: usize, numerator: i64, denominator: i64) -> [i64; 9] {
    let mut out = [0_i64; 9];
    for i in 0..n*n { out[i] = denominator * m[i]; }
    for i in 0..n { out[i*n+i] -= numerator; }
    out
}

fn multiply(a: &[i64; 9], b: &[i64; 9], n: usize) -> [i64; 9] {
    let mut out = [0_i64; 9];
    for row in 0..n { for col in 0..n {
        for k in 0..n { out[row*n+col] += a[row*n+k] * b[k*n+col]; }
    }}
    out
}

fn similar(a: &[i64; 9], b: &[i64; 9], n: usize) -> bool {
    let (aa, ab, ac) = charpoly(a, n);
    let (ba, bb, bc) = charpoly(b, n);
    if (aa, ab, ac) != (ba, bb, bc) { return false; }
    if n == 1 { return true; }
    if n == 2 {
        if aa*aa - 4*ab != 0 { return true; }
        let da = shifted(a, n, -aa, 2);
        let db = shifted(b, n, -aa, 2);
        return rank_singular(&da, n) == rank_singular(&db, n);
    }
    if disc3(aa, ab, ac) != 0 { return true; }
    let q = aa*aa - 3*ab;
    if q == 0 {
        let da = shifted(a, n, -aa, 3);
        let db = shifted(b, n, -aa, 3);
        if rank_singular(&da, n) != rank_singular(&db, n) { return false; }
        return rank_singular(&multiply(&da, &da, n), n)
            == rank_singular(&multiply(&db, &db, n), n);
    }
    let numerator = 9*ac - aa*ab;
    let denominator = 2*q;
    rank_singular(&shifted(a, n, numerator, denominator), n)
        == rank_singular(&shifted(b, n, numerator, denominator), n)
}

#[no_mangle]
pub unsafe extern "C" fn similar_matrices(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=3).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let matrix_size = n * n;
    if length != 1 + 2 * matrix_size { return -1; }
    if values[1..].iter().any(|&value| !(-5..=5).contains(&value)) { return -1; }
    let mut a = [0_i64; 9];
    let mut b = [0_i64; 9];
    a[..matrix_size].copy_from_slice(&values[1..1+matrix_size]);
    b[..matrix_size].copy_from_slice(&values[1+matrix_size..]);
    if similar(&a, &b, n) { 1 } else { 0 }
}
