const MAX_TARGET: i64 = 500;
const COINS: [usize; 8] = [1, 2, 5, 10, 20, 50, 100, 200];

/// Count unordered combinations of the standard UK coins for `target` pence.
#[no_mangle]
pub extern "C" fn problem31(target: i64) -> i64 {
    if !(0..=MAX_TARGET).contains(&target) {
        return -1;
    }
    let target = target as usize;
    let mut ways = [0i64; MAX_TARGET as usize + 1];
    ways[0] = 1;
    for coin in COINS {
        for amount in coin..=target {
            ways[amount] += ways[amount - coin];
        }
    }
    ways[target]
}
