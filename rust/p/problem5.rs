fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn problem5(limit: i64) -> i64 {
    if !(1..=20).contains(&limit) {
        return -1;
    }
    let mut result = 1i64;
    for value in 2..=limit {
        result = (result / gcd(result, value)) * value;
    }
    result
}
