/// Primes strictly between bounded prime endpoints, encoded as ASCII.
const MAX_PRIME_COUNT: usize = 256;

fn is_prime_candidate(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn decimal_length(value: i64) -> usize {
    if value >= 100 { 3 } else if value >= 10 { 2 } else { 1 }
}

unsafe fn write_decimal(output: *mut u8, offset: &mut usize, value: i64) {
    let mut remaining = value;
    if remaining >= 100 {
        *output.add(*offset) = b'0' + (remaining / 100) as u8;
        *offset += 1;
        remaining %= 100;
    }
    if remaining >= 10 {
        *output.add(*offset) = b'0' + (remaining / 10) as u8;
        *offset += 1;
        remaining %= 10;
    }
    *output.add(*offset) = b'0' + remaining as u8;
    *offset += 1;
}

#[no_mangle]
pub unsafe extern "C" fn get_primes_between(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 2 {
        return -1;
    }
    let p1 = *values;
    let p2 = *values.add(1);
    if !(2..=997).contains(&p1)
        || !(2..=997).contains(&p2)
        || p1 >= p2
        || !is_prime_candidate(p1)
        || !is_prime_candidate(p2)
    {
        return -1;
    }

    let mut primes = [0i64; MAX_PRIME_COUNT];
    let mut count = 0usize;
    for candidate in (p1 + 1)..p2 {
        if is_prime_candidate(candidate) {
            primes[count] = candidate;
            count += 1;
        }
    }
    if count == 0 {
        return -1;
    }

    let mut required = count - 1;
    for prime in primes.iter().take(count) {
        required += decimal_length(*prime);
    }
    if output.is_null() || output_capacity < required {
        return -2;
    }

    let mut written = 0usize;
    for (index, prime) in primes.iter().take(count).enumerate() {
        if index != 0 {
            *output.add(written) = b',';
            written += 1;
        }
        write_decimal(output, &mut written, *prime);
    }
    written as i64
}
