/// Encode the first n palindrome primes as little-endian u32 values.
#[no_mangle]
pub unsafe extern "C" fn palindrome_prime(n: i64, output: *mut u8,
                                            output_capacity: usize) -> i64 {
    if n > 16 { return -1; }
    if n <= 0 { return 0; }
    let required = n as usize * 4;
    if output.is_null() || output_capacity < required { return -2; }

    let mut position = 0usize;
    std::ptr::copy_nonoverlapping(2u32.to_le_bytes().as_ptr(), output.add(position), 4);
    position += 4;
    let mut count = 1i64;
    let mut candidate = 3u32;
    while count < n {
        let mut remaining = candidate;
        let mut reversed = 0u32;
        while remaining > 0 {
            reversed = reversed * 10 + remaining % 10;
            remaining /= 10;
        }
        let mut prime = true;
        let mut divisor = 2u32;
        while divisor <= candidate / divisor {
            if candidate % divisor == 0 {
                prime = false;
                break;
            }
            divisor += 1;
        }
        if candidate == reversed && prime {
            std::ptr::copy_nonoverlapping(candidate.to_le_bytes().as_ptr(), output.add(position), 4);
            position += 4;
            count += 1;
        }
        candidate += 2;
    }
    required as i64
}
