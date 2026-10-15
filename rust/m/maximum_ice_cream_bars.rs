/// Buy the largest affordable prefix after sorting the prices.
#[no_mangle]
pub unsafe extern "C" fn maximum_ice_cream_bars(input: *const i64, length: usize) -> i64 {
    if length < 1 || length > 257 || input.is_null() { return -1; }
    let coins = *input;
    let count = length - 1;
    if !(0..=1_000_000).contains(&coins) { return -1; }
    let mut costs = [0i64; 256];
    for index in 0..count {
        let cost = *input.add(index + 1);
        if !(1..=10_000).contains(&cost) { return -1; }
        let mut position = index;
        while position > 0 && costs[position - 1] > cost {
            costs[position] = costs[position - 1];
            position -= 1;
        }
        costs[position] = cost;
    }
    let mut remaining = coins;
    let mut bought = 0i64;
    for &cost in &costs[..count] {
        if cost > remaining { break; }
        remaining -= cost;
        bought += 1;
    }
    bought
}
