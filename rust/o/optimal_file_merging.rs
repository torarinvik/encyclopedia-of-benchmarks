#[no_mangle]
pub unsafe extern "C" fn optimal_file_merging(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > 33 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count = input[0];
    if !(0..=32).contains(&count) || length != count as usize + 1 { return -1; }
    let mut files = [0_i64; 32];
    for i in 0..count as usize {
        if !(0..=1_000_000).contains(&input[i + 1]) { return -1; }
        files[i] = input[i + 1];
    }
    let mut n = count as usize;
    let mut total = 0_i64;
    while n > 1 {
        let (mut a, mut b) = (0_usize, 1_usize);
        if files[b] < files[a] { std::mem::swap(&mut a, &mut b); }
        for i in 2..n {
            if files[i] < files[a] { b = a; a = i; }
            else if files[i] < files[b] { b = i; }
        }
        let merged = files[a] + files[b]; total += merged;
        if a > b { std::mem::swap(&mut a, &mut b); }
        files[a] = merged; files[b] = files[n - 1]; n -= 1;
    }
    total
}
