const MAX_TYPES: usize = 16;
const MAX_CAPACITY: usize = 64;
const MAX_INPUT: usize = 51;

#[no_mangle]
pub unsafe extern "C" fn bounded_knapsack_binary_grouping(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (type_count_value, capacity_value) = (values[0], values[1]);
    if type_count_value < 0
        || type_count_value > MAX_TYPES as i64
        || capacity_value < 0
        || capacity_value > MAX_CAPACITY as i64
    {
        return -1;
    }
    let type_count = type_count_value as usize;
    let capacity = capacity_value as usize;
    if length != 2 + 3 * type_count {
        return -1;
    }
    for item in 0..type_count {
        let weight = values[2 + 3 * item];
        let value = values[3 + 3 * item];
        let count = values[4 + 3 * item];
        if !(1..=16).contains(&weight) || !(0..=100).contains(&value) || !(0..=16).contains(&count) {
            return -1;
        }
    }

    let mut best = [0_i64; MAX_CAPACITY + 1];
    for item in 0..type_count {
        let weight = values[2 + 3 * item] as usize;
        let value = values[3 + 3 * item];
        let mut remaining = values[4 + 3 * item] as usize;
        let mut bundle_size = 1_usize;
        while remaining > 0 {
            let copies = bundle_size.min(remaining);
            let bundle_weight = weight * copies;
            let bundle_value = value * copies as i64;
            if bundle_weight <= capacity {
                let mut limit = capacity;
                loop {
                    let candidate = best[limit - bundle_weight] + bundle_value;
                    best[limit] = best[limit].max(candidate);
                    if limit == bundle_weight {
                        break;
                    }
                    limit -= 1;
                }
            }
            remaining -= copies;
            bundle_size *= 2;
        }
    }
    best[capacity]
}
