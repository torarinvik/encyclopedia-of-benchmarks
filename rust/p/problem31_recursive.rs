const MAX_TARGET: i64 = 200;
const COINS: [i64; 8] = [1, 2, 5, 10, 20, 50, 100, 200];

fn count_ways(target: i64, coin_index: usize) -> i64 {
    if target < 0 {
        return 0;
    }
    if coin_index == 0 {
        return 1;
    }
    let coin = COINS[coin_index];
    count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1)
}

/// Count unordered UK coin combinations using the source's un-memoized recurrence.
#[no_mangle]
pub extern "C" fn problem31_recursive(target: i64) -> i64 {
    if !(0..=MAX_TARGET).contains(&target) {
        return -1;
    }
    count_ways(target, 7)
}
