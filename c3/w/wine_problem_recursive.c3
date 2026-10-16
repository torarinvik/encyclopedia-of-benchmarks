module wine_problem_recursive;

const usz MAX_ITEMS = 14;
const long MAX_PRICE = 1000000;

fn long solve(long* prices, usz count, usz first, usz last) {
    long year = (long)(count - (last - first + 1) + 1);
    if (first == last) return prices[first] * year;
    long sell_first = prices[first] * year + solve(prices, count, first + 1, last);
    long sell_last = prices[last] * year + solve(prices, count, first, last - 1);
    if (sell_first > sell_last) return sell_first;
    return sell_last;
}

fn long wine_problem_recursive(long* prices, usz length) @export("wine_problem_recursive") {
    if (prices == null || length == 0 || length > MAX_ITEMS) return -1;
    for (usz index = 0; index < length; index++)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    return solve(prices, length, 0, length - 1);
}
