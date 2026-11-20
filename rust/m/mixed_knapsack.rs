const MAX_TYPES: usize = 16;
const MAX_CAPACITY: usize = 64;
const MAX_INPUT: usize = 67;

#[no_mangle]
pub unsafe extern "C" fn mixed_knapsack(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, capacity_value) = (values[0], values[1]);
    if !(0..=MAX_TYPES as i64).contains(&n_value)
        || !(0..=MAX_CAPACITY as i64).contains(&capacity_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let capacity = capacity_value as usize;
    if length != 2 + 4 * n {
        return -1;
    }
    for item in 0..n {
        let mode = values[2 + 4 * item];
        let weight = values[3 + 4 * item];
        let value = values[4 + 4 * item];
        let limit = values[5 + 4 * item];
        if !(0..=2).contains(&mode) || !(1..=16).contains(&weight) || !(0..=100).contains(&value)
            || (mode == 0 && limit != 1) || (mode == 1 && limit != 0)
            || (mode == 2 && !(0..=16).contains(&limit))
        {
            return -1;
        }
    }

    let mut best = [0_i64; MAX_CAPACITY + 1];
    for item in 0..n {
        let mode = values[2 + 4 * item];
        let weight = values[3 + 4 * item] as usize;
        let value = values[4 + 4 * item];
        if mode == 0 {
            let mut cap = capacity;
            while cap >= weight {
                best[cap] = best[cap].max(best[cap - weight] + value);
                if cap == weight { break; }
                cap -= 1;
            }
        } else if mode == 1 {
            for cap in weight..=capacity {
                best[cap] = best[cap].max(best[cap - weight] + value);
            }
        } else {
            let mut remaining = values[5 + 4 * item] as usize;
            let mut bundle_size = 1_usize;
            while remaining > 0 {
                let copies = bundle_size.min(remaining);
                let bundle_weight = copies * weight;
                let bundle_value = copies as i64 * value;
                if bundle_weight <= capacity {
                    let mut cap = capacity;
                    while cap >= bundle_weight {
                        best[cap] = best[cap].max(best[cap - bundle_weight] + bundle_value);
                        if cap == bundle_weight { break; }
                        cap -= 1;
                    }
                }
                remaining -= copies;
                bundle_size *= 2;
            }
        }
    }
    best[capacity]
}
