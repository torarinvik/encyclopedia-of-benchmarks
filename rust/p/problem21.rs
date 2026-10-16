fn proper_divisor_sum(value: i64) -> i64 {
    if value <= 1 {
        return 0;
    }
    let mut total = 1;
    let mut divisor = 2;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            let partner = value / divisor;
            total += divisor;
            if partner != divisor {
                total += partner;
            }
        }
        divisor += 1;
    }
    total
}

/// Sum amicable numbers strictly below `limit`.
#[no_mangle]
pub extern "C" fn problem21(limit: i64) -> i64 {
    if !(1..=10000).contains(&limit) {
        return -1;
    }
    let mut total = 0;
    for value in 1..limit {
        let partner = proper_divisor_sum(value);
        if partner != value && proper_divisor_sum(partner) == value {
            total += value;
        }
    }
    total
}
