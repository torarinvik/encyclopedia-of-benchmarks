const MAX_DIMENSION: usize = 8;
const MAX_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub unsafe extern "C" fn bareiss_determinant(input: *const i64, length: usize) -> i64 {
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

    let mut matrix = [0_i64; MAX_DIMENSION * MAX_DIMENSION];
    matrix[..n * n].copy_from_slice(&values[1..]);
    let mut sign = 1_i64;
    let mut previous_pivot = 1_i64;

    for k in 0..n.saturating_sub(1) {
        if matrix[k * n + k] == 0 {
            let Some(replacement) = ((k + 1)..n)
                .find(|&row| matrix[row * n + k] != 0)
            else {
                return 0;
            };
            for column in 0..n {
                matrix.swap(k * n + column, replacement * n + column);
            }
            sign = -sign;
        }

        let pivot = matrix[k * n + k];
        for row in (k + 1)..n {
            for column in (k + 1)..n {
                let numerator = matrix[row * n + column] * pivot
                    - matrix[row * n + k] * matrix[k * n + column];
                matrix[row * n + column] = numerator / previous_pivot;
            }
            matrix[row * n + k] = 0;
        }
        previous_pivot = pivot;
    }
    sign * matrix[(n - 1) * n + n - 1]
}
