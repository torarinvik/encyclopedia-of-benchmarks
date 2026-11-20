const MAX_INDEX: i64 = 8192;

#[no_mangle]
pub unsafe extern "C" fn hofstadter_conway_10000_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || !(2..=MAX_INDEX).contains(&values[0]) { return -1; }

    let target = values[0] as usize;
    let mut a = [0_i64; 8193];
    a[1] = 1;
    a[2] = 1;
    for n in 3..=target {
        let previous = a[n - 1];
        let other = n as i64 - previous;
        if previous < 1 || previous >= n as i64 || other < 1 || other >= n as i64 { return -1; }
        a[n] = a[previous as usize] + a[other as usize];
    }
    a[target]
}
