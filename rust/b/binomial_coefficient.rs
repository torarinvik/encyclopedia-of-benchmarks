/// Calculate C(n, k) by updating one row of Pascal's triangle.
#[no_mangle]
pub extern "C" fn binomial_coefficient(n: u64, k: u64) -> i64 {
    if n > 66 { return -1; }
    if k > n { return 0; }
    if k == 0 { return 1; }
    let mut coefficients = [0i64; 67];
    coefficients[0] = 1;
    for row in 1..=n {
        let mut column = row.min(k);
        while column > 0 {
            coefficients[column as usize] += coefficients[(column - 1) as usize];
            column -= 1;
        }
    }
    coefficients[k as usize]
}
