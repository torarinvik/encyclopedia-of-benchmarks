const MAX_N: i64 = 1000;
const ROW_CAPACITY: usize = 1001;

#[no_mangle]
pub unsafe extern "C" fn binomial_divisibility_primality_test(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let value = *input;
    if !(2..=MAX_N).contains(&value) {
        return -1;
    }

    let n = value as usize;
    let mut coefficients = [0i64; ROW_CAPACITY];
    coefficients[0] = 1;
    for degree in 1..=n {
        coefficients[degree] = 1;
        for column in (1..degree).rev() {
            coefficients[column] =
                (coefficients[column] + coefficients[column - 1]) % value;
        }
    }

    if coefficients[1..n].iter().all(|&coefficient| coefficient == 0) {
        1
    } else {
        0
    }
}
