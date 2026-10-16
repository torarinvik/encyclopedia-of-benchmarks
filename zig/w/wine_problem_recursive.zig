const MAX_ITEMS: usize = 14;
const MAX_PRICE: i64 = 1_000_000;

fn solve(prices: []const i64, first: usize, last: usize) i64 {
    const year: i64 = @intCast(prices.len - (last - first + 1) + 1);
    if (first == last) return prices[first] * year;
    const sell_first = prices[first] * year + solve(prices, first + 1, last);
    const sell_last = prices[last] * year + solve(prices, first, last - 1);
    return @max(sell_first, sell_last);
}

export fn wine_problem_recursive(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_ITEMS) return -1;
    const prices = input[0..length];
    for (prices) |price| {
        if (price < 0 or price > MAX_PRICE) return -1;
    }
    return solve(prices, 0, length - 1);
}
