fn is_pentagonal(value: i64) -> bool {
    if value < 1 {
        return false;
    }
    let discriminant = 24 * value + 1;
    let root = (discriminant as f64).sqrt() as i64;
    root * root == discriminant && (root + 1) % 6 == 0
}

/// Return the first matching pentagonal difference in nested index order.
#[no_mangle]
pub extern "C" fn problem44(limit: i64) -> i64 {
    if !(1..=5000).contains(&limit) {
        return -1;
    }
    for i in 1..limit {
        let first = i * (3 * i - 1) / 2;
        for j in i..limit {
            let second = j * (3 * j - 1) / 2;
            let difference = second - first;
            if is_pentagonal(first + second) && is_pentagonal(difference) {
                return difference;
            }
        }
    }
    -1
}
