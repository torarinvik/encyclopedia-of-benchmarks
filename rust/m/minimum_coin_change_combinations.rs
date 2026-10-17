use std::slice;

const MAX_INPUT: usize = 34;

#[no_mangle]
pub unsafe extern "C" fn minimum_coin_change_combinations(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let target_value = values[0];
    let count_value = values[1];
    if !(-64..=64).contains(&target_value) || !(0..=32).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != count + 2 { return -1; }

    let mut previous = 0i64;
    for &coin in &values[2..] {
        if !(1..=64).contains(&coin) || coin <= previous { return -1; }
        previous = coin;
    }
    if target_value < 0 { return 0; }

    let target = target_value as usize;
    let mut ways = [0i64; 65];
    ways[0] = 1;
    for &coin_value in &values[2..] {
        let coin = coin_value as usize;
        for amount in coin..=target {
            ways[amount] += ways[amount - coin];
        }
    }
    ways[target]
}
