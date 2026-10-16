module wine_problem_memoized;

const usz MAX_ITEMS = 64;
const long MAX_PRICE = 1000000;

fn long solve(long* prices, usz count, usz first, usz last, long* memo) {
    usz slot = first * MAX_ITEMS + last;
    long year = (long)(count - (last - first + 1) + 1);
    if (first == last) { memo[slot] = prices[first] * year; return memo[slot]; }
    if (memo[slot] != 0) return memo[slot];
    long sell_first = prices[first] * year + solve(prices, count, first + 1, last, memo);
    long sell_last = prices[last] * year + solve(prices, count, first, last - 1, memo);
    if (sell_first > sell_last) memo[slot] = sell_first;
    else memo[slot] = sell_last;
    return memo[slot];
}

fn long wine_problem_memoized(long* prices, usz length) @export("wine_problem_memoized") {
    if (prices == null || length == 0 || length > MAX_ITEMS) return -1;
    for (usz index = 0; index < length; index++)
        if (prices[index] < 1 || prices[index] > MAX_PRICE) return -1;
    long[MAX_ITEMS * MAX_ITEMS] memo;
    for (usz index = 0; index < MAX_ITEMS * MAX_ITEMS; index++) memo[index] = 0;
    return solve(prices, length, 0, length - 1, &memo[0]);
}
