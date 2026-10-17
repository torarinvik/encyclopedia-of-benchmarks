fn collatz_length(start: u64) -> u64 {
    let mut current = start;
    let mut length = 1u64;
    while current != 1 {
        if length >= 10_000 { return 0; }
        if current % 2 == 0 {
            current /= 2;
        } else {
            if current > 3_002_399_751_580_330 { return 0; }
            current = 3 * current + 1;
        }
        length += 1;
    }
    length
}

#[no_mangle]
pub extern "C" fn problem014(limit: i64) -> i64 {
    if !(1..=1_000_000).contains(&limit) { return -1; }
    let mut best_start = 1u64;
    let mut best_length = 1u64;
    for start in 2..limit as u64 {
        let length = collatz_length(start);
        if length == 0 { return -1; }
        if length > best_length {
            best_start = start;
            best_length = length;
        }
    }
    best_start as i64
}
