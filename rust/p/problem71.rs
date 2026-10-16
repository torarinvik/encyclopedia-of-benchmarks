/// Find the numerator of the closest bounded fraction below a reduced target.
const MAX_DENOMINATOR: i64 = 1_000_000;

fn gcd_positive(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub unsafe extern "C" fn problem71(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 {
        return -1;
    }
    let target_numerator = *input;
    let target_denominator = *input.add(1);
    let limit = *input.add(2);
    if target_numerator < 1 || target_denominator <= target_numerator ||
        target_denominator > MAX_DENOMINATOR || limit < 1 || limit > MAX_DENOMINATOR ||
        gcd_positive(target_numerator, target_denominator) != 1 {
        return -1;
    }

    let mut best_numerator = 0i64;
    let mut best_denominator = 1i64;
    for current_denominator in 1..=limit {
        let mut current_numerator =
            current_denominator * target_numerator / target_denominator;
        if current_denominator % target_denominator == 0 {
            current_numerator -= 1;
        }
        if current_numerator * best_denominator > current_denominator * best_numerator {
            best_numerator = current_numerator;
            best_denominator = current_denominator;
        }
    }
    best_numerator
}
