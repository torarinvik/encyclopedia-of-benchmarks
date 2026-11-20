const MAX_DIMENSION: usize = 8;
const MAX_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = i64::MIN;

fn bit_count(mut value: usize) -> usize {
    let mut count = 0;
    while value != 0 {
        count += value & 1;
        value >>= 1;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn ryser_permanent(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(1..=MAX_DIMENSION as i64).contains(&values[0]) {
        return INVALID_RESULT;
    }
    let n = values[0] as usize;
    if length != 1 + n * n || values[1..].iter().any(|value| !(-4..=4).contains(value)) {
        return INVALID_RESULT;
    }

    let entries = &values[1..];
    let mut row_sums = [0_i64; MAX_DIMENSION];
    let mut total = 0_i64;
    let mut previous_gray = 0_usize;
    for ordinal in 0..(1_usize << n) {
        let gray = ordinal ^ (ordinal >> 1);
        if ordinal != 0 {
            let changed = gray ^ previous_gray;
            let column = changed.trailing_zeros() as usize;
            let direction = if gray & changed != 0 { 1 } else { -1 };
            for row in 0..n {
                row_sums[row] += direction * entries[row * n + column];
            }
        }

        let mut product = 1_i64;
        for row_sum in &row_sums[..n] {
            product *= row_sum;
        }
        if (n + bit_count(gray)) & 1 != 0 {
            product = -product;
        }
        total += product;
        previous_gray = gray;
    }
    total
}
