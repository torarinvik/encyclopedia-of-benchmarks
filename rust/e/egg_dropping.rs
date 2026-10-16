const INVALID_RESULT: i64 = i64::MIN;
const MAX_EGGS: usize = 12;
const MAX_FLOORS: usize = 128;
const FLOOR_WIDTH: usize = MAX_FLOORS + 1;

#[no_mangle]
pub unsafe extern "C" fn egg_dropping(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_EGGS as i64 ||
        values[1] < 1 || values[1] > MAX_FLOORS as i64 {
        return INVALID_RESULT;
    }

    let eggs = values[0] as usize;
    let floors = values[1] as usize;
    let mut dp = [0_i64; (MAX_EGGS + 1) * FLOOR_WIDTH];

    for egg in 1..=eggs {
        dp[egg * FLOOR_WIDTH + 1] = 1;
    }
    for floor in 1..=floors {
        dp[FLOOR_WIDTH + floor] = floor as i64;
    }
    for egg in 2..=eggs {
        for floor in 2..=floors {
            let mut best = i64::MAX;
            for drop in 1..=floor {
                let breaks = dp[(egg - 1) * FLOOR_WIDTH + drop - 1];
                let survives = dp[egg * FLOOR_WIDTH + floor - drop];
                let worst = 1 + breaks.max(survives);
                best = best.min(worst);
            }
            dp[egg * FLOOR_WIDTH + floor] = best;
        }
    }
    dp[eggs * FLOOR_WIDTH + floors]
}
