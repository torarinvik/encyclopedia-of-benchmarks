#[no_mangle]
pub unsafe extern "C" fn random_permutation_cycle_cap_count(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length != 2 {
        return -1;
    }
    let n_value = *input;
    let cap_value = *input.add(1);
    if !(1..=20).contains(&n_value) || cap_value < 1 || cap_value > n_value {
        return -1;
    }

    let n = n_value as usize;
    let cap = cap_value as usize;
    let mut counts = [0i64; 21];
    counts[0] = 1;
    for size in 1..=n {
        let mut total = 0i64;
        let mut cycle_choices = 1i64;
        let limit = size.min(cap);
        for cycle_length in 1..=limit {
            if cycle_length > 1 {
                cycle_choices *= (size - cycle_length + 1) as i64;
            }
            total += cycle_choices * counts[size - cycle_length];
        }
        counts[size] = total;
    }
    counts[n]
}
