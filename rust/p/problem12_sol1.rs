fn divisor_count(mut value: i64) -> i64 {
    let mut count = 1i64;
    let mut factor = 2i64;
    while factor <= value / factor {
        let mut multiplicity = 0i64;
        while value % factor == 0 {
            value /= factor;
            multiplicity += 1;
        }
        if multiplicity > 0 {
            count *= multiplicity + 1;
        }
        factor += 1;
    }
    if value > 1 {
        count *= 2;
    }
    count
}

#[no_mangle]
pub extern "C" fn problem12_sol1(threshold: i64) -> i64 {
    if threshold != 500 {
        return -1;
    }
    let mut index = 1i64;
    let mut triangular = 1i64;
    loop {
        index += 1;
        triangular += index;
        if divisor_count(triangular) > 500 {
            return triangular;
        }
    }
}
