const MAX_ITEMS: usize = 64;
const MAX_PRICE: i64 = 1_000_000;

fn solve(prices: [*c]const i64, count: usize, first: usize, last: usize, memo: []i64) i64 {
    const slot = first * MAX_ITEMS + last;
    const year: i64 = @intCast(count - (last - first + 1) + 1);
    if (first == last) {
        memo[slot] = prices[first] * year;
        return memo[slot];
    }
    if (memo[slot] != 0) return memo[slot];
    const sell_first = prices[first] * year + solve(prices, count, first + 1, last, memo);
    const sell_last = prices[last] * year + solve(prices, count, first, last - 1, memo);
    memo[slot] = @max(sell_first, sell_last);
    return memo[slot];
}

export fn wine_problem_memoized(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_ITEMS) return -1;
    for (0..length) |index| {
        const price = input[index];
        if (price < 1 or price > MAX_PRICE) return -1;
    }
    var memo: [MAX_ITEMS * MAX_ITEMS]i64 = [_]i64{0} ** (MAX_ITEMS * MAX_ITEMS);
    return solve(input, length, 0, length - 1, memo[0..]);
}
