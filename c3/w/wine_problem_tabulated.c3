module wine_problem_tabulated;

const usz MAX_ITEMS = 64;
const long MAX_PRICE = 1000000;

fn long wine_problem_tabulated(long* prices, usz length) @export("wine_problem_tabulated") {
    if (prices == null || length == 0 || length > MAX_ITEMS) return -1;
    for (usz index = 0; index < length; index++)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    long[MAX_ITEMS * MAX_ITEMS] table;
    for (usz index = 0; index < MAX_ITEMS * MAX_ITEMS; index++) table[index] = 0;
    for (usz width = 1; width <= length; width++) {
        long year = (long)(length - width + 1);
        for (usz first = 0; first + width <= length; first++) {
            usz last = first + width - 1;
            usz slot = first * MAX_ITEMS + last;
            if (first == last) table[slot] = prices[first] * year;
            else {
                long sell_first = prices[first] * year + table[(first + 1) * MAX_ITEMS + last];
                long sell_last = prices[last] * year + table[first * MAX_ITEMS + last - 1];
                if (sell_first > sell_last) table[slot] = sell_first;
                else table[slot] = sell_last;
            }
        }
    }
    return table[length - 1];
}
