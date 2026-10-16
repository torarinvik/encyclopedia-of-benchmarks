const MAX_LIMIT: usize = 28_123;

#[no_mangle]
pub extern "C" fn problem23(limit: i64) -> i64 {
    if !(0..=MAX_LIMIT as i64).contains(&limit) {
        return -1;
    }
    let bound = limit as usize;
    let mut proper_divisor_sums = [0i64; MAX_LIMIT + 1];
    let mut abundant = [false; MAX_LIMIT + 1];
    let mut representable = [false; MAX_LIMIT + 1];

    for divisor in 1..=bound / 2 {
        let mut multiple = 2 * divisor;
        while multiple <= bound {
            proper_divisor_sums[multiple] += divisor as i64;
            multiple += divisor;
        }
    }
    for value in 12..=bound {
        abundant[value] = proper_divisor_sums[value] > value as i64;
    }
    for left in 12..=bound {
        if !abundant[left] {
            continue;
        }
        let mut right = left;
        while right <= bound - left {
            if abundant[right] {
                representable[left + right] = true;
            }
            right += 1;
        }
    }

    let mut total = 0i64;
    for value in 1..=bound {
        if !representable[value] {
            total += value as i64;
        }
    }
    total
}
