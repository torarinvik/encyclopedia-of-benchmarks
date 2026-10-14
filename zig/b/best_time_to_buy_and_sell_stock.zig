/// Maximum profit from one buy followed by one sell.
export fn best_time_to_buy_and_sell_stock(prices: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    var minimum = prices[0];
    var best: i64 = 0;
    for (0..length) |day| {
        const price = prices[day];
        if (price < 0 or price > 1_000_000_000) return -1;
        minimum = @min(minimum, price);
        best = @max(best, price - minimum);
    }
    return best;
}
