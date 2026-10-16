const MAX_EGGS: usize = 8;
const MAX_FLOORS: usize = 32;

#[no_mangle]
pub unsafe extern "C" fn egg_dropping_puzzle(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let eggs_value = *input;
    let floors_value = *input.add(1);
    if !(1..=MAX_EGGS as i64).contains(&eggs_value)
        || !(1..=MAX_FLOORS as i64).contains(&floors_value) { return -1; }

    let eggs = eggs_value as usize;
    let floors = floors_value as usize;
    let mut dp = [[0i64; MAX_FLOORS + 1]; MAX_EGGS + 1];
    for egg in 1..=eggs { dp[egg][1] = 1; }
    for floor_count in 1..=floors { dp[1][floor_count] = floor_count as i64; }

    for egg in 2..=eggs {
        for floor_count in 2..=floors {
            let mut best = (MAX_FLOORS + 1) as i64;
            for drop_floor in 1..=floor_count {
                let broken = dp[egg - 1][drop_floor - 1];
                let survives = dp[egg][floor_count - drop_floor];
                let worst = if broken > survives { broken } else { survives };
                let candidate = worst + 1;
                if candidate < best { best = candidate; }
            }
            dp[egg][floor_count] = best;
        }
    }
    dp[eggs][floors]
}
