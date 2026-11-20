const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_N: i64 = 30;

fn motzkin_number_value(n: usize) -> i64 {
    let mut values = [0i64; 31];
    values[0] = 1;
    if n >= 1 { values[1] = 1; }
    if n >= 2 {
        for size in 2..=n {
            let mut total = values[size - 1];
            for left in 0..size - 1 {
                total += values[left] * values[size - 2 - left];
            }
            values[size] = total;
        }
    }
    values[n]
}

fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > MAX_PARSEABLE_LENGTH || values.len() != 1 { return -1; }
    let n = values[0];
    if !(0..=MAX_N).contains(&n) { return -1; }
    motzkin_number_value(n as usize)
}

#[no_mangle]
pub unsafe extern "C" fn motzkin_number(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
