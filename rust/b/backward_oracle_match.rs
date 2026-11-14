#[no_mangle]
pub unsafe extern "C" fn backward_oracle_match(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=4161).contains(&length) { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    if !(0..=4096).contains(&input[0]) || !(0..=63).contains(&input[1]) { return -2; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + n + m || input[2..].iter().any(|&x| !(97..=122).contains(&x)) { return -2; }
    if m == 0 { return 0; }
    if m > n { return -1; }
    let mut next = [[-1_i32; 26]; 64];
    let mut suffix = [-1_i32; 64];
    for i in 0..m {
        let letter = (input[2 + n + m - 1 - i] - 97) as usize;
        next[i][letter] = (i + 1) as i32;
        let mut k = suffix[i];
        while k >= 0 && next[k as usize][letter] < 0 {
            next[k as usize][letter] = (i + 1) as i32;
            k = suffix[k as usize];
        }
        suffix[i + 1] = if k < 0 { 0 } else { next[k as usize][letter] };
    }
    let mut start = 0;
    while start <= n - m {
        let mut state = 0_usize;
        let mut remaining = m;
        let mut shift = m;
        while remaining > 0 {
            remaining -= 1;
            let dest = next[state][(input[2 + start + remaining] - 97) as usize];
            if dest < 0 { shift = remaining + 1; break; }
            state = dest as usize;
            if remaining == 0 { return start as i64; }
        }
        start += shift;
    }
    -1
}
