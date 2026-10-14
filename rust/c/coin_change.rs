/// Return the minimum number of unlimited coins needed to reach an amount.
#[no_mangle]
pub extern "C" fn coin_change(packed: *const i64, length: usize) -> i64 {
    if length < 2 || length > 130 || packed.is_null() {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let amount = packed[0];
    let coin_count = packed[1];
    if !(0..=512).contains(&amount) || !(0..=128).contains(&coin_count)
        || length != 2 + coin_count as usize
    {
        return -1;
    }
    let coins = &packed[2..];
    if coins.iter().any(|&coin| !(1..=4096).contains(&coin)) {
        return -1;
    }

    let mut minimum = [0i64; 513];
    for current in 1..=amount as usize {
        let mut best = 513i64;
        for &coin in coins {
            let coin = coin as usize;
            if coin <= current && minimum[current - coin] < 513 {
                best = best.min(minimum[current - coin] + 1);
            }
        }
        minimum[current] = best;
    }
    if minimum[amount as usize] < 513 { minimum[amount as usize] } else { -1 }
}
