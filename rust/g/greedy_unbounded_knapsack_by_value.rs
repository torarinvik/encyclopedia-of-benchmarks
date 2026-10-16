const MAX_ITEMS: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn greedy_unbounded_knapsack_by_value(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=18).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (mut remaining, count_value) = (values[0], values[1]);
    if !(0..=1_000_000).contains(&remaining) || !(0..=MAX_ITEMS as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    let mut item_values = [0i64; MAX_ITEMS];
    let mut weights = [0i64; MAX_ITEMS];
    let mut order = [0usize; MAX_ITEMS];
    for index in 0..count {
        item_values[index] = values[2 + index];
        weights[index] = values[2 + count + index];
        if !(0..=1_000_000).contains(&item_values[index]) || !(1..=1_000_000).contains(&weights[index]) { return -1; }
        order[index] = index;
    }
    for index in 1..count {
        let current = order[index];
        let mut position = index;
        while position > 0 && item_values[order[position - 1]] < item_values[current] {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    let mut total_value = 0i64;
    for &item in &order[..count] {
        while remaining >= weights[item] {
            total_value += item_values[item];
            remaining -= weights[item];
        }
    }
    total_value
}
