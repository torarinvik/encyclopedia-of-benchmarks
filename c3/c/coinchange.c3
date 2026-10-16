module coinchange;

const usz MAX_AMOUNT = 30;
const usz MAX_COINS = 8;

fn long coinchange(long* values, usz length) @export("coinchange") {
    if (values == null || length < 2 || length > MAX_COINS + 2) return -1;
    long amount_value = values[0], coin_count_value = values[1];
    if (amount_value < 1 || amount_value > (long)MAX_AMOUNT || coin_count_value < 0 || coin_count_value > (long)MAX_COINS) return -1;
    usz amount = (usz)amount_value, coin_count = (usz)coin_count_value;
    if (length != coin_count + 2) return -1;
    for (usz index = 0; index < coin_count; index++) {
        if (values[index + 2] < 1 || values[index + 2] > (long)MAX_AMOUNT) return -1;
    }

    long[MAX_AMOUNT] combinations = zeroed;
    combinations[0] = 1;
    for (usz coin_index = 0; coin_index < coin_count; coin_index++) {
        usz coin = (usz)values[coin_index + 2];
        for (usz subtotal = coin; subtotal < amount; subtotal++) {
            combinations[subtotal] += combinations[subtotal - coin];
        }
    }
    return combinations[amount - 1];
}
