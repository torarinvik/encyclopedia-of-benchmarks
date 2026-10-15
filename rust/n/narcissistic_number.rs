/// Enumerate narcissistic numbers below limit, memoizing digit powers.
#[no_mangle]
pub unsafe extern "C" fn narcissistic_number(limit: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if limit > 100_000 { return -1; }
    if limit <= 0 { return 0; }
    let mut numbers = [0_i64; 32];
    let mut powers = [0_i64; 60];
    let mut cached = [false; 60];
    let mut count = 0usize;
    for number in 0..limit {
        let mut digits = 1usize;
        let mut remaining = number;
        while remaining >= 10 { remaining /= 10; digits += 1; }
        let mut sum = 0_i64;
        remaining = number;
        while remaining > 0 {
            let digit = (remaining % 10) as usize;
            let key = digits * 10 + digit;
            if !cached[key] {
                let mut power = 1_i64;
                for _ in 0..digits { power *= digit as i64; }
                powers[key] = power;
                cached[key] = true;
            }
            sum += powers[key];
            remaining /= 10;
        }
        if sum == number {
            if count == numbers.len() { return -1; }
            numbers[count] = number;
            count += 1;
        }
    }
    let required = count * 8;
    if required == 0 { return 0; }
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    for &number in &numbers[..count] {
        let bytes = (number as u64).to_be_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(position), 8);
        position += 8;
    }
    required as i64
}
