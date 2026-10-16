const MAX_ITEMS: usize = 64;
const MAX_PRICE: i64 = 1_000_000;

export fn wine_problem_tabulated(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_ITEMS) return -1;
    for (0..length) |index| {
        const price = input[index];
        if (price < 0 or price > MAX_PRICE) return -1;
    }
    var table: [MAX_ITEMS * MAX_ITEMS]i64 = [_]i64{0} ** (MAX_ITEMS * MAX_ITEMS);
    for (1..(length + 1)) |width| {
        const year: i64 = @intCast(length - width + 1);
        for (0..(length - width + 1)) |first| {
            const last = first + width - 1;
            const slot = first * MAX_ITEMS + last;
            if (first == last) {
                table[slot] = input[first] * year;
            } else {
                const sell_first = input[first] * year + table[(first + 1) * MAX_ITEMS + last];
                const sell_last = input[last] * year + table[first * MAX_ITEMS + last - 1];
                table[slot] = @max(sell_first, sell_last);
            }
        }
    }
    return table[length - 1];
}
