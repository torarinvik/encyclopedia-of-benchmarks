const MAX_AMOUNT: usize = 30;
const MAX_COINS: usize = 8;

export fn coinchange(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_COINS + 2) return -1;
    const amount_value = values[0];
    const coin_count_value = values[1];
    if (amount_value < 1 or amount_value > MAX_AMOUNT or coin_count_value < 0 or coin_count_value > MAX_COINS) return -1;
    const amount: usize = @intCast(amount_value);
    const coin_count: usize = @intCast(coin_count_value);
    if (length != coin_count + 2) return -1;
    for (0..coin_count) |index| {
        if (values[index + 2] < 1 or values[index + 2] > MAX_AMOUNT) return -1;
    }

    var combinations: [MAX_AMOUNT]i64 = @splat(0);
    combinations[0] = 1;
    for (0..coin_count) |coin_index| {
        const coin: usize = @intCast(values[coin_index + 2]);
        for (coin..amount) |subtotal| {
            combinations[subtotal] += combinations[subtotal - coin];
        }
    }
    return combinations[amount - 1];
}
