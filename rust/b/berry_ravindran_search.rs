const MAX_INPUT: usize = 274;

#[no_mangle]
pub unsafe extern "C" fn berry_ravindran_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -2; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=256).contains(&values[0]) || !(1..=16).contains(&values[1]) { return -2; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&x| !(0..=15).contains(&x)) { return -2; }
    if m > n { return -1; }
    let p = 2 + n;
    let mut shift = [m + 2; 289];
    for first in 0..17 { shift[first * 17 + values[p] as usize] = m + 1; }
    for i in 0..(m - 1) { shift[values[p + i] as usize * 17 + values[p + i + 1] as usize] = m - i; }
    for second in 0..17 { shift[values[p + m - 1] as usize * 17 + second] = 1; }
    let mut start = 0;
    while start <= n - m {
        let mut i = 0;
        while i < m && values[2 + start + i] == values[p + i] { i += 1; }
        if i == m { return start as i64; }
        let k = start + m;
        if k >= n { break; }
        let first = values[2 + k] as usize;
        let second = if k + 1 < n { values[2 + k + 1] as usize } else { 16 };
        start += shift[first * 17 + second];
    }
    -1
}
