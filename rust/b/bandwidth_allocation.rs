const MAX_USERS: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn bandwidth_allocation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let bandwidth = input[0];
    let count_value = input[1];
    if !(0..=100_000).contains(&bandwidth) || !(0..=MAX_USERS as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    for index in 0..count {
        let demand = input[2 + index];
        let value = input[2 + count + index];
        if !(1..=1_000).contains(&demand) || !(0..=10_000).contains(&value) { return -1; }
    }

    let mut ratios = [0.0_f64; MAX_USERS];
    let mut order = [0_usize; MAX_USERS];
    for index in 0..count {
        ratios[index] = input[2 + count + index] as f64 / input[2 + index] as f64;
        order[index] = index;
    }
    for index in 1..count {
        let key_ratio = ratios[index];
        let key_index = order[index];
        let mut position = index;
        while position > 0 && ratios[position - 1] < key_ratio {
            ratios[position] = ratios[position - 1];
            order[position] = order[position - 1];
            position -= 1;
        }
        ratios[position] = key_ratio;
        order[position] = key_index;
    }

    let mut remaining = bandwidth;
    let mut total = 0_i64;
    for position in 0..count {
        let index = order[position];
        let demand = input[2 + index];
        let value = input[2 + count + index];
        if remaining >= demand {
            total += value;
            remaining -= demand;
        } else {
            total += (ratios[position] * remaining as f64) as i64;
            break;
        }
    }
    total
}
