fn decimal_length(mut value: i64) -> usize {
    let mut length = 1usize;
    while value >= 10 { value /= 10; length += 1; }
    length
}

fn append_decimal(mut value: i64, output: &mut [u8], mut position: usize) -> usize {
    let mut digits = [0u8; 3];
    let mut count = 0usize;
    loop {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output[position] = b'0' + digits[count];
        position += 1;
    }
    position
}

#[no_mangle]
pub extern "C" fn totients_linear_sieve(n: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if n < 1 || n > 80 { return -1; }
    let n = n as usize;
    let mut phi = [0i64; 81];
    let mut composite = [false; 81];
    let mut primes = [0usize; 80];
    let mut prime_count = 0usize;
    phi[1] = 1;
    for i in 2..=n {
        if !composite[i] {
            primes[prime_count] = i;
            prime_count += 1;
            phi[i] = i as i64 - 1;
        }
        for &p in primes[..prime_count].iter() {
            if i * p > n { break; }
            composite[i * p] = true;
            if i % p == 0 {
                phi[i * p] = phi[i] * p as i64;
                break;
            }
            phi[i * p] = phi[i] * (p as i64 - 1);
        }
    }
    let required: usize = phi[1..=n].iter().map(|&v| decimal_length(v)).sum::<usize>() + n - 1;
    if output.is_null() || output_capacity < required { return -2; }
    let bytes = unsafe { std::slice::from_raw_parts_mut(output, required) };
    let mut position = 0usize;
    for i in 1..=n {
        if i > 1 { bytes[position] = b','; position += 1; }
        position = append_decimal(phi[i], bytes, position);
    }
    position as i64
}
