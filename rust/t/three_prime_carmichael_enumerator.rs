const MAX_LIMIT: i64 = 61;
const MAX_TRIPLES: usize = 69;
const MAX_OUTPUT_BYTES: usize = 4 + 12 * MAX_TRIPLES;

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    if value % 2 == 0 {
        return value == 2;
    }
    let mut divisor = 3i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 2;
    }
    true
}

fn put_u32(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: u32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn three_prime_carmichael_enumerator(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let limit = *input;
    if !(2..=MAX_LIMIT).contains(&limit) {
        return -1;
    }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut count = 0usize;
    let mut position = 4usize;
    let mut p1 = 2i64;
    while p1 <= limit {
        if is_prime(p1) {
            let mut h3 = 2i64;
            while h3 < p1 {
                let g = h3 + p1;
                let mut d = 1i64;
                while d < g {
                    if (g * (p1 - 1)) % d == 0 {
                        let square = (p1 * p1) % h3;
                        let negative_square = if square == 0 { 0 } else { h3 - square };
                        if negative_square == d % h3 {
                            let p2 = 1 + (p1 - 1) * g / d;
                            if p2 > p1 && is_prime(p2) {
                                let p3 = 1 + p1 * p2 / h3;
                                if p3 > p2 && is_prime(p3)
                                    && (p2 * p3) % (p1 - 1) == 1
                                {
                                    if count >= MAX_TRIPLES {
                                        return -1;
                                    }
                                    put_u32(&mut staged, position, p1 as u32);
                                    put_u32(&mut staged, position + 4, p2 as u32);
                                    put_u32(&mut staged, position + 8, p3 as u32);
                                    position += 12;
                                    count += 1;
                                }
                            }
                        }
                    }
                    d += 1;
                }
                h3 += 1;
            }
        }
        p1 += 1;
    }

    put_u32(&mut staged, 0, count as u32);
    if output.is_null() || capacity < position {
        return -2;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, position);
    position as i64
}
