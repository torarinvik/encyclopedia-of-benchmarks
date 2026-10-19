const SIEVE_LIMIT: i64 = 8192;
const MAX_ITERATIONS: i64 = 64;

#[no_mangle]
pub unsafe extern "C" fn sieve(iterations: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if iterations < 0 || iterations > MAX_ITERATIONS { return -1; }

    let mut flags = [0_u8; (SIEVE_LIMIT + 1) as usize];
    let mut count = 0_i64;
    for _ in 0..iterations {
        count = 0;
        for value in 2..=SIEVE_LIMIT { flags[value as usize] = 1; }
        for value in 2..=SIEVE_LIMIT {
            if flags[value as usize] != 0 {
                count += 1;
                let mut multiple = value + value;
                while multiple <= SIEVE_LIMIT {
                    flags[multiple as usize] = 0;
                    multiple += value;
                }
            }
        }
    }

    let mut reversed_digits = [0_u8; 10];
    let mut digit_count = 0;
    let mut remaining = count;
    loop {
        reversed_digits[digit_count] = b'0' + (remaining % 10) as u8;
        digit_count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    let required = 8 + digit_count;
    if output.is_null() || output_capacity < required { return -2; }
    unsafe {
        let prefix = b"Count: ";
        for (index, byte) in prefix.iter().enumerate() { *output.add(index) = *byte; }
        for index in 0..digit_count {
            *output.add(7 + index) = reversed_digits[digit_count - index - 1];
        }
        *output.add(required - 1) = b'\n';
    }
    required as i64
}
