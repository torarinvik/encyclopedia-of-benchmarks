const MAX_ITEMS: usize = 14;
const MAX_PRICE: i64 = 1_000_000;

fn solve(prices: &[i64], first: usize, last: usize) -> i64 {
    let year = (prices.len() - (last - first + 1) + 1) as i64;
    if first == last {
        return prices[first] * year;
    }
    let sell_first = prices[first] * year + solve(prices, first + 1, last);
    let sell_last = prices[last] * year + solve(prices, first, last - 1);
    sell_first.max(sell_last)
}

#[no_mangle]
pub unsafe extern "C" fn wine_problem_recursive(prices: *const i64, length: usize) -> i64 {
    if prices.is_null() || length == 0 || length > MAX_ITEMS {
        return -1;
    }
    let values = std::slice::from_raw_parts(prices, length);
    if values.iter().any(|&price| !(0..=MAX_PRICE).contains(&price)) {
        return -1;
    }
    solve(values, 0, length - 1)
}
