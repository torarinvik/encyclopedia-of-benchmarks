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

    let mut costs = [0u16; MAX_N + 2];
    let mut next_costs = [0u16; MAX_N];
    costs[0] = 32768;
    costs[n + 1] = 32768;
    for column in 0..n {
        costs[column + 1] = (*input.add(1 + column) + 100) as u16;
    }
    for row in 1..n {
        for column in 0..n {
            let best = costs[column].min(costs[column + 1]).min(costs[column + 2]);
            next_costs[column] = best + (*input.add(1 + row * n + column) + 100) as u16;
        }
        costs[1..n + 1].copy_from_slice(&next_costs[..n]);
    }
    let mut minimum = costs[1];
    for column in 1..n {
        minimum = minimum.min(costs[column + 1]);
    }
    i64::from(minimum) - 100 * n as i64
}
