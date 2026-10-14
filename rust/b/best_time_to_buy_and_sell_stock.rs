/// Maximum profit from one buy followed by one sell.
#[no_mangle]
pub extern "C" fn best_time_to_buy_and_sell_stock(prices: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    let prices = unsafe { std::slice::from_raw_parts(prices, length) };
    let mut minimum = prices[0];
    let mut best = 0_i64;
    for &price in prices {
        if !(0..=1_000_000_000).contains(&price) { return -1; }
        minimum = minimum.min(price);
        best = best.max(price - minimum);
    }
    best
}
