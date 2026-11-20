fn integer_sqrt_i64(value: i64, upper: i64) -> i64 {
    let mut low = 0i64;
    let mut high = upper + 1;
    while low + 1 < high {
        let middle = low + (high - low) / 2;
        if middle * middle <= value { low = middle; }
        else { high = middle; }
    }
    low
}

#[no_mangle]
pub unsafe extern "C" fn fermat_factorization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (number, max_steps) = (values[0], values[1]);
    if number < 3 || number > 1_000_000_000_000 || number % 2 == 0
        || max_steps < 0 || max_steps > 4096 { return -1; }
    let mut candidate = integer_sqrt_i64(number, 1_000_000);
    if candidate * candidate < number { candidate += 1; }
    for _ in 0..max_steps {
        let difference = candidate * candidate - number;
        let root = integer_sqrt_i64(difference, candidate);
        if root * root == difference {
            let factor = candidate - root;
            if factor > 1 && factor < number { return factor; }
        }
        candidate += 1;
    }
    0
}
