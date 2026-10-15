const MAX_INDEX: i64 = 230;

fn binomial_coefficient(n: i64, k: i64) -> i64 {
    if k == 0 || k == n {
        return 1;
    }
    if n < 0 {
        return 0;
    }
    binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1)
}

#[no_mangle]
pub extern "C" fn binomial_sequence(index: i64) -> i64 {
    if index < 0 || index > MAX_INDEX {
        return -1;
    }
    let mut row = 0i64;
    let mut row_start = 0i64;
    while index >= row_start + row + 1 {
        row_start += row + 1;
        row += 1;
    }
    binomial_coefficient(row, index - row_start)
}
