fn feasible(input: &[i64], n: usize, groups: usize, limit: i64) -> bool {
    let mut used_groups = 1usize;
    let mut current_sum = 0i64;
    for &value in &input[2..2 + n] {
        if current_sum + value > limit {
            used_groups += 1;
            current_sum = value;
            if used_groups > groups {
                return false;
            }
        } else {
            current_sum += value;
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn linear_partition_minimax(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 35 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=32).contains(&values[0]) || values[1] < 1 || values[1] > values[0] {
        return -1;
    }
    let n = values[0] as usize;
    let groups = values[1] as usize;
    if length != n + 2 || values[2..].iter().any(|&value| !(0..=1000).contains(&value)) {
        return -1;
    }

    let mut low = 0i64;
    let mut upper = 0i64;
    for &value in &values[2..] {
        low = low.max(value);
        upper += value;
    }
    while low < upper {
        let middle = low + (upper - low) / 2;
        if feasible(values, n, groups, middle) {
            upper = middle;
        } else {
            low = middle + 1;
        }
    }
    low
}
