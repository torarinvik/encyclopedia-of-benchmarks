/// Encode ascending prime/exponent pairs as little-endian u32 values.
fn factor_pairs(value: i64, primes: &mut [u32; 10], exponents: &mut [u32; 10]) -> usize {
    if value <= 1 { primes[0] = value as u32; exponents[0] = 1; return 1; }
    let mut count = 0usize;
    let mut remaining = value;
    let mut divisor = 2i64;
    while divisor <= remaining / divisor {
        if remaining % divisor == 0 {
            let mut exponent = 0u32;
            while remaining % divisor == 0 {
                remaining /= divisor;
                exponent += 1;
            }
            primes[count] = divisor as u32;
            exponents[count] = exponent;
            count += 1;
        }
        divisor += 1;
    }
    if remaining > 1 {
        primes[count] = remaining as u32;
        exponents[count] = 1;
        count += 1;
    }
    count
}

fn write_u32le(value: u32, output: *mut u8, position: usize) {
    for byte in 0..4 {
        unsafe { output.add(position + byte).write((value >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub extern "C" fn factorize(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(0..=1_000_005).contains(&value) { return -1; }
    let mut primes = [0u32; 10];
    let mut exponents = [0u32; 10];
    let count = factor_pairs(value, &mut primes, &mut exponents);
    let required = count * 8;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..count {
        write_u32le(primes[index], output, 8 * index);
        write_u32le(exponents[index], output, 8 * index + 4);
    }
    required as i64
}
