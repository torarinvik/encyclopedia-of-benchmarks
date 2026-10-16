fn divisor_count(value: i64) -> i64 {
    let mut remaining = value;
    let mut factor = 2i64;
    let mut count = 1i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            let mut exponent = 0i64;
            while remaining % factor == 0 {
                remaining /= factor;
                exponent += 1;
            }
            count *= exponent + 1;
        }
        factor += 1;
    }
    if remaining > 1 {
        count *= 2;
    }
    count
}

#[no_mangle]
pub extern "C" fn problem12(minimum_divisors: i64) -> i64 {
    if !(0..=500).contains(&minimum_divisors) {
        return -1;
    }
    for index in 1..=12_375i64 {
        let mut left = index;
        let mut right = index + 1;
        if index % 2 == 0 { left /= 2; } else { right /= 2; }
        if divisor_count(left) * divisor_count(right) >= minimum_divisors {
            return index * (index + 1) / 2;
        }
    }
    -1
}
