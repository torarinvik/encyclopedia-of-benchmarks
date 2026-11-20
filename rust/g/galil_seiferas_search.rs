const MAX_INPUT: usize = 162;
const K: usize = 4;

fn factorize(x: &[i64]) -> (usize, usize, usize) {
    let m = x.len();
    let (mut s, mut p1, mut q1) = (0usize, 1usize, 0usize);
    loop {
        while s + p1 + q1 < m && x[s + q1] == x[s + p1 + q1] { q1 += 1; }
        if p1 + q1 >= K * p1 {
            let (mut p2, mut q2) = (q1, 0usize);
            loop {
                while p2 + q2 < K * p2 && s + p2 + q2 < m &&
                    x[s + q2] == x[s + p2 + q2] { q2 += 1; }
                if p2 + q2 == K * p2 {
                    loop {
                        while s + p1 + q1 < m && x[s + q1] == x[s + p1 + q1] { q1 += 1; }
                        while p1 + q1 >= K * p1 { s += p1; q1 -= p1; }
                        if s + p1 + q1 == m { return (s, p1, q1); }
                        p1 += q1 / K + 1;
                        q1 = 0;
                        if p1 >= p2 { break; }
                    }
                    break;
                }
                if s + p2 + q2 == m { return (s, p1, q1); }
                if q2 == p1 + q1 { p2 += p1; q2 -= p1; }
                else { p2 += q2 / K + 1; q2 = 0; }
            }
        } else {
            if s + p1 + q1 == m { return (s, p1, q1); }
            p1 += q1 / K + 1;
            q1 = 0;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn galil_seiferas_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -2; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=128).contains(&values[0]) || !(1..=32).contains(&values[1]) { return -2; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&x| !(0..=15).contains(&x)) { return -2; }
    if m > n { return 0; }
    let text = &values[2..2 + n];
    let pattern = &values[2 + n..];
    let (s, p1, q1) = factorize(pattern);
    let (mut p, mut q, mut matches) = (0usize, 0usize, 0i64);
    while p <= n - m {
        while s + q < m && pattern[s + q] == text[p + s + q] { q += 1; }
        if q == m - s {
            let mut i = 0;
            while i < s && pattern[i] == text[p + i] { i += 1; }
            if i == s { matches += 1; }
        }
        if q == p1 + q1 { p += p1; q -= p1; }
        else { p += q / K + 1; q = 0; }
    }
    matches
}
