const MAX_DIGITS: i64 = 3;
const MAX_VALID_INPUT_LENGTH: usize = 1;
const MAX_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;

fn is_palindrome(value: i64) -> bool {
    let mut remaining = value;
    let mut reversed = 0i64;
    while remaining > 0 {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    reversed == value
}

#[no_mangle]
pub unsafe extern "C" fn euler_problem_4(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < MAX_VALID_INPUT_LENGTH || length > MAX_INPUT_LENGTH {
        return -1;
    }
    if length != MAX_VALID_INPUT_LENGTH {
        return -1;
    }
    let digit_count = *input;
    if !(1..=MAX_DIGITS).contains(&digit_count) {
        return -1;
    }

    let mut lower = 1i64;
    for _ in 1..digit_count {
        lower *= 10;
    }
    let upper = lower * 10 - 1;
    let mut largest = 0i64;
    for left in lower..=upper {
        for right in lower..=upper {
            let product = left * right;
            if product > largest && is_palindrome(product) {
                largest = product;
            }
        }
    }
    largest
}
