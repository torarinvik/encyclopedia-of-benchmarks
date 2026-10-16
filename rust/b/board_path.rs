#[no_mangle]
pub unsafe extern "C" fn board_path(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let a = std::slice::from_raw_parts(input, length);
    if a[0] < 0 || a[1] < 0 || a[0] > 30 || a[1] > 30 || a[0] > a[1] { return -1; }
    let (start, end) = (a[0] as usize, a[1] as usize);
    let mut ways = [0i64; 31];
    ways[end] = 1;
    for i in (start..end).rev() {
        for die in 1..=6 { if i + die <= end { ways[i] += ways[i + die]; } }
    }
    ways[start]
}
