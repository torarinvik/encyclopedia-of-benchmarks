const MAX_ITEMS: usize = 64;
const MAX_PRICE: i64 = 1_000_000;

fn solve(prices: &[i64], first: usize, last: usize, memo: &mut [i64]) -> i64 {
    let slot = first * MAX_ITEMS + last;
    let year = (prices.len() - (last - first + 1) + 1) as i64;
    if first == last {
        memo[slot] = prices[first] * year;
        return memo[slot];
    }
    if memo[slot] != 0 {
        return memo[slot];
    }
    let sell_first = prices[first] * year + solve(prices, first + 1, last, memo);
    let sell_last = prices[last] * year + solve(prices, first, last - 1, memo);
    memo[slot] = sell_first.max(sell_last);
    memo[slot]
}

#[no_mangle]
pub unsafe extern "C" fn wine_problem_memoized(prices: *const i64, length: usize) -> i64 {
    if prices.is_null() || length == 0 || length > MAX_ITEMS {
        return -1;
    }
    let values = std::slice::from_raw_parts(prices, length);
    if values.iter().any(|&price| !(1..=MAX_PRICE).contains(&price)) {
        return -1;
    }
    let mut memo = [0_i64; MAX_ITEMS * MAX_ITEMS];
    solve(values, 0, length - 1, &mut memo)
}
