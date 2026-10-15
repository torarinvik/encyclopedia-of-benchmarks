const MAX_N: usize = 100;
const INVALID_RESULT: i64 = -10001;

#[no_mangle]
pub unsafe extern "C" fn minimum_falling_path_sum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 { return INVALID_RESULT; }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) { return INVALID_RESULT; }
    let n = n_value as usize;
    if length != 1 + n * n { return INVALID_RESULT; }
    for index in 0..n * n {
        let value = *input.add(1 + index);
        if !(-100..=100).contains(&value) { return INVALID_RESULT; }
    }

    let mut costs = [0i64; MAX_N];
    let mut next_costs = [0i64; MAX_N];
    for column in 0..n { costs[column] = *input.add(1 + column); }
    for row in 1..n {
        for column in 0..n {
            let mut best = costs[column];
            if column > 0 && costs[column - 1] < best { best = costs[column - 1]; }
            if column + 1 < n && costs[column + 1] < best { best = costs[column + 1]; }
            next_costs[column] = best + *input.add(1 + row * n + column);
        }
        for column in 0..n { costs[column] = next_costs[column]; }
    }
    let mut minimum = costs[0];
    for column in 1..n {
        if costs[column] < minimum { minimum = costs[column]; }
    }
    minimum
}
