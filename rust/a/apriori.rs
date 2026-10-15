const MAX_TRANSACTIONS: usize = 64;
const MAX_ITEMSETS: usize = 1 << 12;
const SUPPORT_SCALE: i64 = 1_000_000;

fn item_count(mut mask: u32) -> u32 {
    let mut count = 0;
    while mask != 0 {
        count += mask & 1;
        mask >>= 1;
    }
    count
}

fn support_is_frequent(support: i64, transaction_count: i64, threshold_ppm: i64) -> bool {
    support * SUPPORT_SCALE >= threshold_ppm * transaction_count
}

#[no_mangle]
pub unsafe extern "C" fn apriori(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let transaction_count = values[0];
    let items = values[1];
    let min_support_ppm = values[2];
    let min_confidence_ppm = values[3];
    if !(1..=MAX_TRANSACTIONS as i64).contains(&transaction_count) || !(1..=12).contains(&items) ||
        !(1..=SUPPORT_SCALE).contains(&min_support_ppm) || !(0..=SUPPORT_SCALE).contains(&min_confidence_ppm) ||
        length != 4 + transaction_count as usize { return -1; }

    let mask_limit = 1u32 << items;
    let mut transactions = [0u32; MAX_TRANSACTIONS];
    for index in 0..transaction_count as usize {
        if values[4 + index] < 0 || values[4 + index] as u64 >= mask_limit as u64 { return -1; }
        transactions[index] = values[4 + index] as u32;
    }

    let mut supports = [0i64; MAX_ITEMSETS];
    let mut previous = [false; MAX_ITEMSETS];
    let mut all_frequent = [false; MAX_ITEMSETS];
    let mut current = [false; MAX_ITEMSETS];
    let mut mask = 1u32;
    while mask < mask_limit {
        let mut support = 0;
        for transaction in &transactions[..transaction_count as usize] {
            if transaction & mask == mask { support += 1; }
        }
        if support_is_frequent(support, transaction_count, min_support_ppm) {
            supports[mask as usize] = support;
            previous[mask as usize] = true;
            all_frequent[mask as usize] = true;
        }
        mask <<= 1;
    }

    for size in 2..=items as u32 {
        current.fill(false);
        let mut found = false;
        for candidate in 1..mask_limit {
            if item_count(candidate) != size { continue; }
            let mut all_subsets_frequent = true;
            for item in 0..items as u32 {
                let bit = 1u32 << item;
                if candidate & bit != 0 && !previous[(candidate ^ bit) as usize] {
                    all_subsets_frequent = false;
                    break;
                }
            }
            if !all_subsets_frequent { continue; }
            let mut support = 0;
            for transaction in &transactions[..transaction_count as usize] {
                if transaction & candidate == candidate { support += 1; }
            }
            if support_is_frequent(support, transaction_count, min_support_ppm) {
                supports[candidate as usize] = support;
                current[candidate as usize] = true;
                all_frequent[candidate as usize] = true;
                found = true;
            }
        }
        previous = current;
        if !found { break; }
    }

    let mut rule_count = 0i64;
    for candidate in 1..mask_limit {
        if !all_frequent[candidate as usize] || item_count(candidate) < 2 { continue; }
        let mut antecedent = (candidate - 1) & candidate;
        while antecedent != 0 {
            if supports[candidate as usize] * SUPPORT_SCALE >= min_confidence_ppm * supports[antecedent as usize] {
                rule_count += 1;
            }
            antecedent = (antecedent - 1) & candidate;
        }
    }
    rule_count
}
