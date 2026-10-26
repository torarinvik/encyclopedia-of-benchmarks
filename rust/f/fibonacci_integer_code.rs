#[no_mangle]
pub unsafe extern "C" fn fibonacci_integer_code(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 33 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0];
    if !(1..=32).contains(&n0) || length != n0 as usize + 1 { return -1; }
    let n = n0 as usize;
    if values[1..].iter().any(|&x| x < 0 || x > 1_000_000) { return -1; }
    let mut fib = [0u64; 30]; fib[0] = 1; fib[1] = 2; let mut fib_count = 2usize;
    while fib_count < 30 && fib[fib_count - 1] + fib[fib_count - 2] <= 1_000_001 {
        fib[fib_count] = fib[fib_count - 1] + fib[fib_count - 2]; fib_count += 1;
    }
    let mut staged = [0u8; 960]; let mut out = 0usize;
    for &value in &values[1..] {
        let mut remaining = value as u64 + 1;
        let mut top = 0usize;
        while top + 1 < fib_count && fib[top + 1] <= remaining { top += 1; }
        let mut bits = [0u8; 30];
        for j in (0..=top).rev() {
            if fib[j] <= remaining { bits[j] = 1; remaining -= fib[j]; }
        }
        for bit in bits.iter().take(top + 1) { staged[out] = b'0' + *bit; out += 1; }
        staged[out] = b'1'; out += 1;
    }
    if output.is_null() || capacity < out { return -2; }
    std::slice::from_raw_parts_mut(output, out).copy_from_slice(&staged[..out]);
    out as i64
}
