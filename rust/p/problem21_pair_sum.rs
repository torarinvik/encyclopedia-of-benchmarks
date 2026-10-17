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

/// Sum both members of each amicable pair whose smaller member is < `limit`.
#[no_mangle]
pub extern "C" fn problem21_pair_sum(limit: i64) -> i64 {
    if !(2..=10000).contains(&limit) {
        return -1;
    }
    let mut total = 0;
    for smaller in 2..limit {
        let larger = proper_divisor_sum(smaller);
        if larger > smaller && proper_divisor_sum(larger) == smaller {
            total += smaller + larger;
        }
    }
    total
}
