const MAX_AMOUNT: usize = 30;
const MAX_COINS: usize = 8;

/// Count source-compatible coin-type combinations for amount minus one.
#[no_mangle]
pub unsafe extern "C" fn coinchange(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_COINS + 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let amount_value = input[0];
    let coin_count_value = input[1];
    if !(1..=MAX_AMOUNT as i64).contains(&amount_value)
        || !(0..=MAX_COINS as i64).contains(&coin_count_value) { return -1; }
    let amount = amount_value as usize;
    let coin_count = coin_count_value as usize;
    if length != coin_count + 2 { return -1; }
    let coins = &input[2..];
    if coins.iter().any(|&coin| !(1..=MAX_AMOUNT as i64).contains(&coin)) { return -1; }

    let mut combinations = [0i64; MAX_AMOUNT];
    combinations[0] = 1;
    for &coin_value in coins {
        let coin = coin_value as usize;
        for subtotal in coin..amount {
            combinations[subtotal] += combinations[subtotal - coin];
        }
    }
    combinations[amount - 1]
}
